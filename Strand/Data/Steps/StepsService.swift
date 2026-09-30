import Foundation
import Combine
import StrandAnalytics
import WhoopStore

/// The steps engine every steps surface reads: the resolved history window, today's live count, and the
/// iPhone pedometer's collection and banking.
///
/// WHAT IT DOES
/// - Resolves a year of days through `Repository.stepInputs` + `StepsResolver` (the ONE resolver), and
///   re-resolves on every repository refresh, Apple Health sync, backfill and day change.
/// - On iOS, while the app is active and Motion & Fitness access is granted, streams the pedometer's running
///   total from local midnight and folds it into today, so the count moves as you walk.
/// - Backfills CoreMotion's seven-day history into the store (daily totals, distance and floors in
///   `metricSeries`, hour buckets in `appleStepHour`, both under `StepsPrefs.phoneDeviceId`) so the phone's
///   history outlives that window. A watermark means each backfill re-reads only the last couple of hours,
///   not the week.
///
/// KEEPING THE MAIN ACTOR LIGHT. Store reads and writes happen on the `WhoopStore` actor and the backfill's
/// pedometer queries in a detached task. What stays here is bookkeeping plus re-resolving a single day per
/// live update. Live updates publish at most every `publishInterval`, and the backfill that banks them runs at
/// most every `persistInterval` while walking (plus once on the way to the background).
///
/// It never asks for Motion & Fitness access by itself: the prompt comes only from `requestPhoneAccess()`,
/// which the Steps screen and card call from an explicit tap, the same "rationale first" rule the Apple
/// Health bridge follows.
@MainActor
final class StepsService: ObservableObject {
    static let shared = StepsService()

    /// What the steps surfaces render.
    struct Snapshot: Equatable {
        /// The device's local calendar day when this was built: the in-progress day.
        var today = ""
        /// Oldest day the window covers.
        var windowStart = ""
        /// Every source's reading per day, the live phone total folded into today.
        var inputs = StepsInputs()
        /// The resolved count per day.
        var days: [String: ResolvedStepDay] = [:]
        /// Today's stored hour buckets, per source that banked hours.
        var todayHours: [StepSource: [Int]] = [:]
        /// False until the first load lands, so views can tell "no steps" from "not read yet".
        var loaded = false

        var todayResolved: ResolvedStepDay? { days[today] }
    }

    @Published private(set) var snapshot = Snapshot()
    @Published private(set) var phoneAccess: PhoneStepAccess = PhonePedometer.access
    @Published private(set) var isStreaming = false

    /// The pedometer's latest running total for today, ahead of the throttled publish. Read by
    /// `Repository.stepInputs` so a surface that loads on its own sees the same live count.
    private(set) var livePhone: LivePhoneSteps?

    static let publishInterval: TimeInterval = 3
    static let persistInterval: TimeInterval = 5 * 60
    /// CoreMotion keeps about a week of pedometer history on the device.
    nonisolated static let phoneHistoryDays = 7
    /// How far before the watermark each backfill starts again: the coprocessor can post a recent hour's
    /// steps a little late, so the newest banked hours are re-read rather than trusted.
    nonisolated static let backfillOverlap: TimeInterval = 2 * 3_600

    private weak var repo: Repository?
    private let pedometer = PhonePedometer()
    private var refreshSubscription: AnyCancellable?
    private var dayChangeObserver: NSObjectProtocol?
    private var appActive = false
    private var reloadTask: Task<Void, Never>?
    private var publishTask: Task<Void, Never>?
    private var backfillTask: Task<Void, Never>?
    private var lastPublish = Date.distantPast
    private var lastBackfill = Date.distantPast
    /// Oldest day a screen asked to see; the window reaches back to it.
    private var coverFrom: String?
    /// Hour buckets already read for days other than today (they no longer change).
    private var pastHours: [String: [StepSource: [Int]]] = [:]

    private init() {}

    // MARK: - Lifecycle

    /// Attach to the repository and load. Idempotent: every steps surface calls it on appear, and the iOS
    /// app calls it on every foreground.
    func activate(repo: Repository) {
        if self.repo !== repo {
            self.repo = repo
            // A strap offload, an import or a re-score bumps `refreshSeq`; debounced because a sync can bump
            // it several times in a row.
            refreshSubscription = repo.$refreshSeq
                .dropFirst()
                .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
                .sink { [weak self] _ in
                    Task { @MainActor in self?.repositoryDidRefresh() }
                }
        }
        if dayChangeObserver == nil {
            dayChangeObserver = NotificationCenter.default.addObserver(
                forName: .NSCalendarDayChanged, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.dayDidChange() }
            }
        }
        phoneAccess = PhonePedometer.access
        if !snapshot.loaded || snapshot.today != Repository.localDayKey(Date()) {
            scheduleReload(from: nil)
        }
    }

    /// iOS foreground: start the pedometer stream if permitted, back-fill what CoreMotion banked while the
    /// app was away, and re-read (Apple Health may have synced too).
    func appDidBecomeActive(repo: Repository) {
        appActive = true
        activate(repo: repo)
        if snapshot.loaded, snapshot.today != Repository.localDayKey(Date()) { dayDidChange() }
        startStreamingIfPermitted()
        runBackfill(force: true)
        scheduleReload(from: nil)
    }

    /// iOS background: stop streaming and bank the day so far. If the process is suspended before that
    /// finishes, nothing is lost: the watermark has not moved, so the next foreground re-reads it.
    func appDidEnterBackground() {
        appActive = false
        stopStreaming()
        runBackfill(force: true)
    }

    /// The repository re-published (a strap sync, an import, the periodic re-score, which also runs while a
    /// connected strap keeps the app alive in the background). Re-read the window, and bank the pedometer at
    /// most every `persistInterval`: that is what lets a goal reached with the app in the background still
    /// be noticed on the next such refresh rather than only at the next foreground.
    private func repositoryDidRefresh() {
        runBackfill(force: false)
        scheduleReload(from: nil)
    }

    /// Apple Health just synced. Its day totals and hours land in the store without necessarily moving
    /// `refreshSeq`, so re-read the recent month explicitly.
    func healthDataDidChange() {
        let today = Repository.localDayKey(Date())
        scheduleReload(from: StepsDayKeys.adding(-30, to: today))
    }

    /// Ask for Motion & Fitness access. Call ONLY from a user's tap: on a fresh install the pedometer query
    /// below is what shows the system prompt, and it returns once the wearer has answered.
    func requestPhoneAccess() async {
        guard PhonePedometer.access == .notDetermined else {
            phoneAccess = PhonePedometer.access
            return
        }
        let now = Date()
        _ = await pedometer.query(from: Calendar.current.startOfDay(for: now), to: now)
        phoneAccess = PhonePedometer.access
        guard phoneAccess == .authorized else { return }
        #if os(iOS)
        // The tap itself proves the app is in the foreground.
        appActive = true
        #endif
        startStreamingIfPermitted()
        runBackfill(force: true)
    }

    /// Make sure the window reaches back to `day` (a focus day more than a year old).
    func ensureCovers(_ day: String) {
        guard snapshot.loaded, day < snapshot.windowStart else { return }
        coverFrom = StepsDayKeys.adding(-30, to: day) ?? day
        scheduleReload(from: nil)
    }

    /// Forget everything the iPhone banked. Apple Health's and the strap's data stay; a still-granted
    /// pedometer starts banking again from what CoreMotion still holds.
    func deletePhoneHistory() async {
        guard let repo, let store = await repo.storeHandle() else { return }
        try? await PhoneStepsStore.deleteAll(from: store)
        UserDefaults.standard.removeObject(forKey: StepsPrefs.phoneWatermarkKey)
        livePhone = nil
        pastHours.removeAll()
        scheduleReload(from: nil)
    }

    /// Hour buckets for `day`: today's from the snapshot, any other day's read once and remembered.
    func hours(for day: String) async -> [StepSource: [Int]] {
        if day == snapshot.today { return snapshot.todayHours }
        if let cached = pastHours[day] { return cached }
        guard let repo else { return [:] }
        let read = await repo.stepHours(day: day)
        pastHours[day] = read
        return read
    }

    // MARK: - Loading

    /// Re-read the window. `from` nil reloads it all; a day re-reads only `from...today` and keeps the rest,
    /// which is what a backfill or a Health sync needs (they only move the last few days).
    private func scheduleReload(from: String?) {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            await self?.reload(from: from)
        }
    }

    private func reload(from partialFrom: String?) async {
        guard let repo else { return }
        let today = Repository.localDayKey(Date())
        guard let defaultStart = StepsDayKeys.adding(-(StepsPrefs.historyDays - 1), to: today) else { return }
        let wantedStart = min(defaultStart, coverFrom ?? defaultStart)
        var inputs: StepsInputs
        let windowStart: String
        if let partialFrom, snapshot.loaded, snapshot.today == today, snapshot.windowStart <= wantedStart {
            let recent = await repo.stepInputs(from: partialFrom, to: today)
            guard !Task.isCancelled else { return }
            // Read the snapshot AFTER the await: a live publish may have moved today meanwhile.
            inputs = snapshot.inputs
            inputs.replacing(from: partialFrom, to: today, with: recent)
            windowStart = snapshot.windowStart
            // Those days' hours may have moved too (a backfill or a Health sync writes recent hours).
            pastHours = pastHours.filter { $0.key < partialFrom }
        } else {
            inputs = await repo.stepInputs(from: wantedStart, to: today)
            guard !Task.isCancelled else { return }
            windowStart = wantedStart
            pastHours.removeAll()
        }
        let hours = await repo.stepHours(day: today)
        guard !Task.isCancelled else { return }
        rebuild(inputs: inputs, today: today, windowStart: windowStart, hours: hours)
    }

    /// Resolve the whole window and publish it.
    private func rebuild(inputs: StepsInputs, today: String, windowStart: String, hours: [StepSource: [Int]]) {
        var inputs = inputs
        if let live = livePhone, live.day == today { inputs.foldLivePhone(live) }
        var days: [String: ResolvedStepDay] = [:]
        for day in inputs.resolved(inProgressDay: today) { days[day.day] = day }
        snapshot = Snapshot(today: today, windowStart: windowStart, inputs: inputs, days: days,
                            todayHours: hours, loaded: true)
        lastPublish = Date()
        evaluateGoal()
    }

    private func evaluateGoal() {
        StepGoalNotifier.evaluate(day: snapshot.today, steps: snapshot.todayResolved?.steps, goal: StepsPrefs.goal)
    }

    // MARK: - Live pedometer

    private func startStreamingIfPermitted() {
        phoneAccess = PhonePedometer.access
        guard appActive, phoneAccess == .authorized, !isStreaming else { return }
        let midnight = Calendar.current.startOfDay(for: Date())
        pedometer.startLive(from: midnight) { [weak self] reading in
            Task { @MainActor in self?.handleLive(reading) }
        }
        isStreaming = true
    }

    private func stopStreaming() {
        guard isStreaming else { return }
        pedometer.stopLive()
        isStreaming = false
    }

    private func handleLive(_ reading: PedometerReading) {
        let today = Repository.localDayKey(Date())
        // A stream still counting from yesterday's midnight (the day turned mid-walk) is restarted by
        // `dayDidChange`; its totals belong to yesterday and must not be read as today's.
        guard Repository.localDayKey(reading.start) == today else { return }
        livePhone = LivePhoneSteps(day: today, steps: reading.steps,
                                   distanceM: reading.distanceM, floorsUp: reading.floorsUp)
        schedulePublish()
        if Date().timeIntervalSince(lastBackfill) >= Self.persistInterval { runBackfill(force: false) }
    }

    /// Publish the live total at most every `publishInterval`, always the latest one.
    private func schedulePublish() {
        guard publishTask == nil else { return }
        let wait = max(0, Self.publishInterval - Date().timeIntervalSince(lastPublish))
        publishTask = Task { [weak self] in
            if wait > 0 { try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000)) }
            guard let self else { return }
            self.publishTask = nil
            self.publishLive()
        }
    }

    /// Re-resolve ONLY today with the live total folded in; the rest of the window cannot have moved.
    private func publishLive() {
        guard snapshot.loaded, let live = livePhone, live.day == snapshot.today else { return }
        var next = snapshot
        next.inputs.foldLivePhone(live)
        let candidates = next.inputs.candidates[live.day] ?? StepDayCandidates()
        next.days[live.day] = StepsResolver.resolve(day: live.day, candidates: candidates, isInProgressDay: true)
        guard next != snapshot else { return }
        snapshot = next
        lastPublish = Date()
        evaluateGoal()
    }

    private func dayDidChange() {
        let wasStreaming = isStreaming
        stopStreaming()
        livePhone = nil
        pastHours.removeAll()
        if wasStreaming { startStreamingIfPermitted() }
        // The backfill re-reads from the watermark's day, which finalises the day that just ended.
        runBackfill(force: true)
        scheduleReload(from: nil)
    }

    // MARK: - Backfill

    /// Bank what CoreMotion holds since the watermark (minus the overlap), off the main actor.
    private func runBackfill(force: Bool) {
        guard phoneAccess == .authorized, backfillTask == nil, let repo else { return }
        if !force, Date().timeIntervalSince(lastBackfill) < Self.persistInterval { return }
        lastBackfill = Date()
        let pedometer = self.pedometer
        let watermark = UserDefaults.standard.object(forKey: StepsPrefs.phoneWatermarkKey) as? Int
        backfillTask = Task { [weak self] in
            let store = await repo.storeHandle()
            var result: BackfillResult?
            if let store {
                result = await Task.detached(priority: .utility) {
                    await StepsService.backfill(pedometer: pedometer, store: store, now: Date(),
                                                calendar: .current, watermark: watermark)
                }.value
            }
            guard let self else { return }
            self.backfillTask = nil
            guard let result else { return }
            UserDefaults.standard.set(result.watermark, forKey: StepsPrefs.phoneWatermarkKey)
            self.scheduleReload(from: result.firstDay)
        }
    }

    struct BackfillResult: Sendable {
        /// Start of the hour the backfill stopped in (that hour is still being counted, so not final).
        let watermark: Int
        /// The oldest day it wrote.
        let firstDay: String
    }

    /// Read CoreMotion's history since `watermark` (or its whole seven days) and bank it: one whole-day
    /// reading per local day (steps, distance, floors) and one reading per clock hour. Queries run one at a
    /// time; `CMPedometer` makes no promise about concurrent queries on one instance, and after the first
    /// run each pass is only a few hours. Returns nil, and so never advances the watermark, when nothing
    /// could be read or written.
    nonisolated static func backfill(pedometer: PhonePedometer, store: WhoopStore, now: Date,
                                     calendar: Calendar, watermark: Int?) async -> BackfillResult? {
        let todayStart = calendar.startOfDay(for: now)
        guard let earliest = calendar.date(byAdding: .day, value: -(phoneHistoryDays - 1), to: todayStart)
        else { return nil }
        var from = earliest
        if let watermark {
            let resume = Date(timeIntervalSince1970: TimeInterval(watermark)).addingTimeInterval(-backfillOverlap)
            from = max(earliest, min(resume, now))
        }

        var days: [(day: String, reading: PedometerReading)] = []
        var dayStart = calendar.startOfDay(for: from)
        while dayStart < now {
            guard let next = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
            if let reading = await pedometer.query(from: dayStart, to: min(next, now)) {
                days.append((day: Repository.localDayKey(dayStart), reading: reading))
            }
            dayStart = next
        }
        guard !days.isEmpty else { return nil }

        var hours: [(ts: Int, steps: Int)] = []
        var hourStart = calendar.dateInterval(of: .hour, for: from)?.start ?? from
        while hourStart < now {
            let end = min(hourStart.addingTimeInterval(3_600), now)
            // Only hours that counted something are banked, the same convention Apple Health's hours
            // follow: a missing hour reads as zero.
            if let reading = await pedometer.query(from: hourStart, to: end), reading.steps > 0 {
                hours.append((ts: Int(hourStart.timeIntervalSince1970), steps: reading.steps))
            }
            hourStart = hourStart.addingTimeInterval(3_600)
        }

        do {
            try await PhoneStepsStore.save(days: days, to: store)
            try await PhoneStepsStore.save(hours: hours, to: store)
        } catch {
            return nil
        }
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return BackfillResult(watermark: Int(currentHour.timeIntervalSince1970),
                              firstDay: days[0].day)
    }
}
