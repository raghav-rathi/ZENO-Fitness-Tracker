#!/usr/bin/env python3
"""steps_probe: look for a WHOOP 4.0's own step counter in the raw frames ZENO saved during a sync.

Read-only and offline. It works on a COPY of ZENO's data folder pulled from the iPhone after a sync that ran with
raw saving switched on (see README.md). Nothing here talks to the band.

    steps_probe.py census DATA_DIR
        Which packet types and history layouts the band sent, and how many history records per minute.

    steps_probe.py scan DATA_DIR --tz America/New_York \\
            --still 2026-10-09T10:00 2026-10-09T10:05 \\
            --arms  2026-10-09T10:05 2026-10-09T10:07 \\
            --walk  2026-10-09T10:07 2026-10-09T10:13 500 \\
            --still 2026-10-09T10:13 2026-10-09T10:15 \\
            --walk  2026-10-09T10:15 2026-10-09T10:20 300 \\
            --still 2026-10-09T10:20 2026-10-09T10:25
        For every byte position of the history records, read as 1-, 2- and 4-byte numbers, find the ones that
        behave like a counter: flat while still, rising in step with the counted walks, little rise during the
        arm-only movement. Bytes 92-93 of layout 24 (where another project found a motion counter) are reported
        first whatever they score.

    steps_probe.py text DATA_DIR
        Readable text in the non-history packets (strap logs) that mentions steps.

DATA_DIR holds whoop.sqlite and its -wal/-shm files. Frames come from the `rawBatch` table: each blob is a 4-byte
little-endian length, then a raw-deflate stream of [count u32][len u32][frame]... Frames use the WHOOP 4.0
envelope [0xAA][len u16][crc8][type][seq][cmd][payload][crc32]; a history record (type 47) carries its layout in
the seq byte and its Unix time at byte 11.
"""

import argparse
import bisect
import datetime as dt
import os
import sqlite3
import statistics
import struct
import sys
import zlib
from collections import Counter, defaultdict

HISTORY_TYPE = 47
FIRST_LOOK = (24, 92, 2)  # layout 24, bytes 92-93, a 2-byte number


# ---------------------------------------------------------------------------------------------- reading frames

def open_db(data_dir):
    path = data_dir if data_dir.endswith(".sqlite") else os.path.join(data_dir, "whoop.sqlite")
    if not os.path.exists(path):
        sys.exit(f"steps_probe: no database at {path}")
    return sqlite3.connect(path)


def inflate(blob):
    """A rawBatch blob: 4-byte LE uncompressed length, then raw deflate (Apple's COMPRESSION_ZLIB)."""
    if len(blob) < 4:
        return b""
    body = bytes(blob[4:])
    for wbits in (-15, 15):
        try:
            return zlib.decompress(body, wbits)
        except zlib.error:
            continue
    return b""


def unpack(data):
    """[count u32][len u32][bytes]... -> list of frames."""
    if len(data) < 4:
        return []
    count = struct.unpack_from("<I", data, 0)[0]
    off, frames = 4, []
    for _ in range(count):
        if off + 4 > len(data):
            break
        n = struct.unpack_from("<I", data, off)[0]
        off += 4
        if off + n > len(data):
            break
        frames.append(data[off:off + n])
        off += n
    return frames


def frame_ok(f):
    """A whole WHOOP 4.0 frame whose CRC-32 trailer matches."""
    if len(f) < 12 or f[0] != 0xAA:
        return False
    declared = struct.unpack_from("<H", f, 1)[0]
    if declared + 4 != len(f):
        return False
    return zlib.crc32(f[4:-4]) & 0xFFFFFFFF == struct.unpack_from("<I", f, len(f) - 4)[0]


def read_frames(db):
    """Every CRC-valid frame saved in rawBatch, in capture order, plus a count of the ones that were not."""
    good, bad = [], 0
    rows = db.execute("SELECT framesBlob FROM rawBatch ORDER BY capturedAt, batchId").fetchall()
    for (blob,) in rows:
        for f in unpack(inflate(blob)):
            if frame_ok(f):
                good.append(f)
            else:
                bad += 1
    return good, bad


def history_records(frames):
    """(unix, layout, frame) for every history record, oldest first, one per (layout, unix)."""
    seen, out = set(), []
    for f in frames:
        if f[4] != HISTORY_TYPE or len(f) < 15:
            continue
        unix = struct.unpack_from("<I", f, 11)[0]
        key = (f[5], unix)
        if key in seen:
            continue
        seen.add(key)
        out.append((unix, f[5], f))
    out.sort(key=lambda r: r[0])
    return out


# ---------------------------------------------------------------------------------------------- census

def census(args):
    db = open_db(args.data_dir)
    frames, bad = read_frames(db)
    if not frames:
        sys.exit("steps_probe: no raw frames saved. Was raw saving on for the sync? See README.md.")
    tz = zone(args.tz)
    types = Counter(f[4] for f in frames)
    print(f"{len(frames):,} CRC-valid frames ({bad:,} others skipped)")
    print("Packet types: " + ", ".join(f"{t} x{n:,}" for t, n in sorted(types.items())))
    recs = history_records(frames)
    if not recs:
        print("No history records (type 47).")
        return
    layouts = Counter(r[1] for r in recs)
    lengths = Counter((r[1], len(r[2])) for r in recs)
    print("History layouts: " + ", ".join(f"v{v} x{n:,}" for v, n in sorted(layouts.items())))
    print("Record sizes: " + ", ".join(f"v{v} {size} bytes x{n:,}" for (v, size), n in sorted(lengths.items())))
    first, last = recs[0][0], recs[-1][0]
    print(f"From {local(first, tz)} to {local(last, tz)}")
    per_minute = Counter(r[0] // 60 for r in recs)
    span = max(1, (last - first) // 60 + 1)
    counts = [per_minute.get(first // 60 + i, 0) for i in range(span)]
    covered = sum(1 for c in counts if c > 0)
    print(f"Minutes with any record: {covered:,} of {span:,}; records per covered minute: "
          f"median {statistics.median([c for c in counts if c > 0]):.0f}")
    print("Records per hour:")
    per_hour = Counter(r[0] // 3600 for r in recs)
    for h in sorted(per_hour):
        print(f"  {local(h * 3600, tz)}  {per_hour[h]:5,}")


# ---------------------------------------------------------------------------------------------- scan

WIDTHS = [(1, "<B", 1 << 8), (2, "<H", 1 << 16), (2, ">H", 1 << 16), (4, "<I", 1 << 32), (4, ">I", 1 << 32)]


def value_at(series, ts, before):
    """The series value at the last record at or before `ts` (before=True) or the first at or after it.
    `series` is sorted by time."""
    times = [t for t, _ in series]
    if before:
        i = bisect.bisect_right(times, ts) - 1
        return series[i][1] if i >= 0 else None
    i = bisect.bisect_left(times, ts)
    return series[i][1] if i < len(series) else None


def rise(series, start, end, modulus):
    """How much a counter rose over [start, end], wrap-aware; None when the window has no records around it."""
    a, b = value_at(series, start, True), value_at(series, end, False)
    if a is None or b is None:
        return None
    return (b - a) % modulus


def drops(series, start, end, modulus):
    """Times the value went down inside the window (a wrap is not a drop)."""
    inside = [v for t, v in series if start <= t <= end]
    n = 0
    for a, b in zip(inside, inside[1:]):
        if b < a and (b - a) % modulus > modulus // 2:
            n += 1
    return n


def candidates(recs, windows):
    by_layout = defaultdict(list)
    for unix, layout, f in recs:
        by_layout[layout].append((unix, f))
    walks = [w for w in windows if w["kind"] == "walk"]
    stills = [w for w in windows if w["kind"] == "still"]
    arms = [w for w in windows if w["kind"] == "arms"]
    found = []
    for layout, rows in by_layout.items():
        size = min(len(f) for _, f in rows)
        for off in range(7, size - 4):
            for width, fmt, modulus in WIDTHS:
                if off + width > size - 4:
                    continue
                series = [(t, struct.unpack_from(fmt, f, off)[0]) for t, f in rows]
                walk_rises = [rise(series, w["start"], w["end"], modulus) for w in walks]
                if any(r is None or r == 0 for r in walk_rises):
                    continue
                ratios = [r / w["steps"] for r, w in zip(walk_rises, walks)]
                still_rises = [rise(series, w["start"], w["end"], modulus) or 0 for w in stills]
                arm_rises = [rise(series, w["start"], w["end"], modulus) or 0 for w in arms]
                down = sum(drops(series, w["start"], w["end"], modulus) for w in walks)
                spread = (max(ratios) / min(ratios)) if min(ratios) > 0 else float("inf")
                walk_total = sum(walk_rises)
                still_share = sum(still_rises) / walk_total
                arm_rate = (sum(arm_rises) / max(1, sum(w["end"] - w["start"] for w in arms))) if arms else 0
                walk_rate = walk_total / max(1, sum(w["end"] - w["start"] for w in walks))
                found.append({
                    "layout": layout, "offset": off, "width": width, "format": fmt,
                    "ratios": ratios, "spread": spread, "still_share": still_share, "drops": down,
                    "arm_vs_walk": (arm_rate / walk_rate) if walk_rate else 0, "walk_rises": walk_rises,
                    "still_rises": still_rises, "arm_rises": arm_rises,
                })
    return found


def verdict(c):
    near_count = any(abs(r - 1) <= 0.10 or abs(r - 0.5) <= 0.05 for r in c["ratios"])
    if c["drops"] == 0 and c["still_share"] <= 0.02 and c["spread"] <= 1.10 and near_count and c["arm_vs_walk"] <= 0.2:
        return "step counter?"
    if c["drops"] == 0 and c["still_share"] <= 0.05 and c["spread"] <= 1.25 and 1.0 <= min(c["ratios"]) <= 1.6:
        return "motion counter?"
    if c["drops"] == 0 and c["still_share"] <= 0.05 and c["spread"] <= 1.25:
        return "counter-like"
    return ""


def describe(c):
    ratios = ", ".join(f"{r:.2f}" for r in c["ratios"])
    return (f"v{c['layout']} @{c['offset']}-{c['offset'] + c['width'] - 1} {c['format']:>3}  "
            f"per step {ratios}  walks +{', +'.join(str(r) for r in c['walk_rises'])}  "
            f"still +{sum(c['still_rises'])}  arms +{sum(c['arm_rises'])}  drops {c['drops']}")


def scan(args):
    tz = zone(args.tz)
    windows = []
    for kind in ("still", "arms", "walk"):
        for spec in getattr(args, kind) or []:
            w = {"kind": kind, "start": parse_time(spec[0], tz), "end": parse_time(spec[1], tz)}
            if kind == "walk":
                if len(spec) < 3:
                    sys.exit("steps_probe: --walk needs START END STEPS")
                w["steps"] = int(spec[2])
            windows.append(w)
    if not any(w["kind"] == "walk" for w in windows):
        sys.exit("steps_probe: give at least one --walk START END STEPS")
    db = open_db(args.data_dir)
    frames, _ = read_frames(db)
    recs = history_records(frames)
    if not recs:
        sys.exit("steps_probe: no history records saved. Was raw saving on for the sync? See README.md.")
    # Only the session matters, with a margin either side for the value just before and just after it.
    lo = min(w["start"] for w in windows) - 300
    hi = max(w["end"] for w in windows) + 300
    recs = [r for r in recs if lo <= r[0] <= hi]
    for w in windows:
        n = sum(1 for r in recs if w["start"] <= r[0] <= w["end"])
        label = w["kind"] + (f" {w['steps']} steps" if w["kind"] == "walk" else "")
        print(f"{label:>16}  {local(w['start'], tz)} to {local(w['end'], tz)}  {n:,} history records")
    found = candidates(recs, windows)
    first = [c for c in found if (c["layout"], c["offset"], c["width"]) == FIRST_LOOK and c["format"] == "<H"]
    print("\nBytes 92-93 (layout 24, little-endian):")
    if first:
        print("  " + describe(first[0]) + (f"  [{verdict(first[0])}]" if verdict(first[0]) else ""))
    else:
        print("  did not rise during the walks, or no layout-24 records in them")
    ranked = sorted(found, key=lambda c: (verdict(c) == "", c["drops"], c["still_share"], c["spread"]))
    print("\nBest candidates:")
    shown = 0
    for c in ranked:
        if shown >= args.top:
            break
        tag = verdict(c)
        if not tag and shown >= 5:
            break
        print(f"  {describe(c)}" + (f"  [{tag}]" if tag else ""))
        shown += 1
    if not any(verdict(c) for c in found):
        print("  nothing behaves like a counter in the history records; try `text`, and see README.md")


# ---------------------------------------------------------------------------------------------- text

def text(args):
    db = open_db(args.data_dir)
    frames, _ = read_frames(db)
    hits = Counter()
    for f in frames:
        if f[4] == HISTORY_TYPE:
            continue
        payload = f[7:-4]
        run, strings = bytearray(), []
        for b in payload:
            if 32 <= b < 127:
                run.append(b)
            else:
                if len(run) >= 6:
                    strings.append(run.decode("ascii"))
                run = bytearray()
        if len(run) >= 6:
            strings.append(run.decode("ascii"))
        for s in strings:
            if any(word in s.lower() for word in args.words):
                hits[(f[4], s)] += 1
    if not hits:
        print("No readable text mentioning " + ", ".join(args.words) + ".")
    for (ptype, s), n in hits.most_common():
        print(f"type {ptype} x{n}: {s}")


# ---------------------------------------------------------------------------------------------- helpers

def zone(name):
    if name:
        from zoneinfo import ZoneInfo
        return ZoneInfo(name)
    return dt.datetime.now().astimezone().tzinfo


def parse_time(text_value, tz):
    t = dt.datetime.fromisoformat(text_value)
    if t.tzinfo is None:
        t = t.replace(tzinfo=tz)
    return int(t.timestamp())


def local(unix, tz):
    return dt.datetime.fromtimestamp(unix, tz).strftime("%Y-%m-%d %H:%M:%S")


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="command", required=True)
    c = sub.add_parser("census", help="what the band sent")
    c.add_argument("data_dir")
    c.add_argument("--tz")
    c.set_defaults(func=census)
    s = sub.add_parser("scan", help="find a counter that rose with the counted walks")
    s.add_argument("data_dir")
    s.add_argument("--tz")
    s.add_argument("--walk", nargs="+", action="append", metavar=("START", "END STEPS"))
    s.add_argument("--still", nargs=2, action="append", metavar=("START", "END"))
    s.add_argument("--arms", nargs=2, action="append", metavar=("START", "END"))
    s.add_argument("--top", type=int, default=15)
    s.set_defaults(func=scan)
    t = sub.add_parser("text", help="strap log text that mentions steps")
    t.add_argument("data_dir")
    t.add_argument("--words", nargs="+", default=["step", "pedo"])
    t.set_defaults(func=text)
    args = p.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
