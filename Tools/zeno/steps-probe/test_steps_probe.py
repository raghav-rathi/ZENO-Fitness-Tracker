"""Tests for steps_probe: a synthetic sync with a step counter and a motion counter planted in layout-24 records."""

import io
import os
import sqlite3
import struct
import tempfile
import unittest
import zlib
from contextlib import redirect_stdout

import steps_probe


def frame(ptype, seq, cmd, payload):
    """A WHOOP 4.0 frame with valid CRCs (CRC-8 is not checked by the probe, so it is left zero)."""
    inner = bytes([ptype, seq, cmd]) + payload
    declared = len(inner) + 4
    return (bytes([0xAA]) + struct.pack("<H", declared) + b"\x00" + inner
            + struct.pack("<I", zlib.crc32(inner) & 0xFFFFFFFF))


def v24_record(unix, steps_counter, ticks):
    body = bytearray(104)
    body[0] = 0xAA
    struct.pack_into("<I", body, 7, unix - 1_700_000_000)   # a record counter
    struct.pack_into("<I", body, 11, unix)
    body[21] = 72
    struct.pack_into("<H", body, 84, steps_counter % 65_536)  # a planted step counter
    struct.pack_into("<H", body, 92, ticks % 65_536)          # a planted motion counter
    # The envelope puts the payload at byte 7, so the fields above keep their frame offsets.
    return frame(47, 24, body[6], bytes(body[7:100]))


def raw_blob(frames):
    packed = struct.pack("<I", len(frames)) + b"".join(struct.pack("<I", len(f)) + f for f in frames)
    comp = zlib.compressobj(wbits=-15)
    deflated = comp.compress(packed) + comp.flush()
    return struct.pack("<I", len(packed)) + deflated


class StepsProbeTests(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        db = sqlite3.connect(os.path.join(self.dir, "whoop.sqlite"))
        db.execute("CREATE TABLE rawBatch (batchId TEXT PRIMARY KEY, capturedAt INTEGER, framesBlob BLOB)")
        # 10:00-10:25 at 1 Hz: still 5 min, arms 2 min, walk 500 steps over 6 min, still 2 min, walk 300 over 5 min.
        start = 1_791_000_000
        self.start = start
        phases = [("still", 300, 0), ("arms", 120, 0), ("walk", 360, 500), ("still", 120, 0),
                  ("walk", 300, 300), ("still", 300, 0)]
        steps = ticks = 0.0
        frames = []
        t = start
        for kind, secs, count in phases:
            for _ in range(secs):
                if kind == "walk":
                    steps += count / secs
                    ticks += 1.2 * count / secs
                elif kind == "arms":
                    ticks += 0.3
                frames.append(v24_record(t, int(steps), int(ticks)))
                t += 1
        frames.append(frame(50, 0, 1, b"\x00\x00\x00step_detect: on\x00"))
        half = len(frames) // 2
        db.execute("INSERT INTO rawBatch VALUES ('a', 1, ?)", (raw_blob(frames[:half]),))
        db.execute("INSERT INTO rawBatch VALUES ('b', 2, ?)", (raw_blob(frames[half:]),))
        db.commit()
        db.close()

    def stamp(self, seconds):
        import datetime as dt
        return dt.datetime.fromtimestamp(self.start + seconds, dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")

    def run_probe(self, *argv):
        out = io.StringIO()
        with redirect_stdout(out):
            steps_probe.main(list(argv))
        return out.getvalue()

    def test_frames_round_trip_and_bad_frames_are_skipped(self):
        db = steps_probe.open_db(self.dir)
        frames, bad = steps_probe.read_frames(db)
        self.assertEqual(bad, 0)
        self.assertEqual(len(steps_probe.history_records(frames)), 1_500)
        broken = bytearray(frames[0])
        broken[20] ^= 0xFF
        self.assertFalse(steps_probe.frame_ok(bytes(broken)))

    def test_census_reports_layout_and_density(self):
        out = self.run_probe("census", self.dir, "--tz", "UTC")
        self.assertIn("v24 x1,500", out)
        self.assertIn("104 bytes", out)
        self.assertIn("records per covered minute: median 60", out)

    def test_scan_finds_the_step_and_motion_counters(self):
        s = self.stamp
        out = self.run_probe("scan", self.dir, "--tz", "UTC",
                             "--still", s(0), s(300), "--arms", s(300), s(420),
                             "--walk", s(420), s(780), "500", "--still", s(780), s(900),
                             "--walk", s(900), s(1_200), "300", "--still", s(1_200), s(1_500))
        self.assertIn("v24 @84-85  <H  per step 1.00, 1.00", out)
        self.assertIn("[step counter?]", out)
        first = out.split("Bytes 92-93")[1].split("Best candidates")[0]
        self.assertIn("per step 1.20, 1.20", first)
        self.assertIn("[motion counter?]", first)

    def test_text_finds_log_lines_about_steps(self):
        out = self.run_probe("text", self.dir)
        self.assertIn("type 50 x1: step_detect: on", out)


if __name__ == "__main__":
    unittest.main()
