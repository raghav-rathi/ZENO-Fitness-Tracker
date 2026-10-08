import Foundation

/// Per-day reuse of the strap's walking split by clock hour (`StepsHourMerge.walkingByHour`), persisted across
/// launches like `StepsMotionCache`.
///
/// It reuses that cache's key on purpose: the day fold's key (owner, gravity row count, newest gravity row) is
/// the witness of one day's gravity stream, and the strap banks heart rate in the same history records, so the
/// two move together. A day is re-split exactly when its daily fold is re-folded, and the owner the fold was
/// measured against is recovered from the key rather than resolved a second time.
///
/// A derived cache: a payload that is missing, unreadable or written by another `foldVersion` is discarded and
/// costs one re-split. Like `StepsMotionCache` it must stay out of backups, because it describes the strap's
/// rows as they were on one device.
public enum StepsHourWalkCache {
    /// One day's entry: the day fold's key, and the strap's walking per clock hour (keyed by hour start).
    public typealias Entry = (key: String, hours: [Int: StepsHourMerge.HourWalk])

    /// Bump on any change to `StepsHourMerge.walkingByHour` that moves what it returns for the same samples.
    public static let foldVersion = 1

    /// The device the day fold was measured against, recovered from a `StepsMotionCache.cacheKey`
    /// ("owner|count|maxTs"). nil for a key that is not one.
    public static func owner(fromCacheKey key: String) -> String? {
        let parts = key.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 3, Int(parts[parts.count - 1]) != nil, Int(parts[parts.count - 2]) != nil else {
            return nil
        }
        let owner = parts.dropLast(2).joined(separator: "|")
        return owner.isEmpty ? nil : owner
    }

    /// Render for storage, days in sorted order so an unchanged cache renders identically. One line per day:
    /// `day<TAB>key<TAB>hour:walkingMinutes:rows,...`.
    public static func serialize(_ entries: [String: Entry]) -> String {
        var out = header
        for day in entries.keys.sorted() {
            guard let e = entries[day] else { continue }
            let hours = e.hours.keys.sorted().compactMap { h -> String? in
                guard let w = e.hours[h] else { return nil }
                return "\(h):\(w.walkingMinutes):\(w.rows)"
            }.joined(separator: ",")
            out += "\n\(day)\t\(e.key)\t\(hours)"
        }
        return out
    }

    /// Parse a stored payload. Empty on anything it cannot vouch for: a wrong or missing header, too many
    /// entries. A malformed line is skipped (that day is re-split).
    public static func deserialize(_ raw: String) -> [String: Entry] {
        var lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first == Substring(header) else { return [:] }
        lines.removeFirst()
        guard lines.count <= maxEntries else { return [:] }
        var out: [String: Entry] = [:]
        lineLoop: for line in lines {
            let f = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard f.count == 3, !f[0].isEmpty, !f[1].isEmpty else { continue }
            var hours: [Int: StepsHourMerge.HourWalk] = [:]
            if !f[2].isEmpty {
                for cell in f[2].split(separator: ",") {
                    let p = cell.split(separator: ":")
                    guard p.count == 3, let h = Int(p[0]), let walking = Int(p[1]), let rows = Int(p[2]),
                          walking >= 0, rows >= 0 else { continue lineLoop }
                    hours[h] = StepsHourMerge.HourWalk(walkingMinutes: walking, rows: rows)
                }
            }
            out[String(f[0])] = (key: String(f[1]), hours: hours)
        }
        return out
    }

    private static var header: String { "stepsHourWalk v\(foldVersion)" }

    /// The writer prunes to the calibration window every pass, so a payload far above it is not this cache's.
    private static let maxEntries = 512
}
