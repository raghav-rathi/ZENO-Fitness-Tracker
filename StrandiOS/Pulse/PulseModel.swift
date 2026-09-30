#if os(iOS)
import SwiftUI
import Combine
import Observation
import StrandDesign
import StrandAnalytics
import WhoopStore

/// The ONE main-actor object Pulse's views observe.
///
/// It owns the selected day, captures a `PulseRequest` from the repository in a single main-actor hop,
/// hands it to the off-main `PulseSnapshotBuilder`, and publishes the snapshot that comes back. It
/// rebuilds when the repository's `refreshSeq` moves, when the day changes, and when a display
/// preference changes; nothing else invalidates a snapshot.
///
/// `@Observable`, so a view re-renders only for the properties it actually reads: the Home dials for
/// `home`, the day title for `dayOffset`, the Strain dive for `strain`. A published build is dropped if
/// the refresh or the day moved on while it ran, so a slow build can never overwrite a newer one.
@MainActor
@Observable
final class PulseModel {

    // MARK: Published state

    /// The repository refresh the current snapshots describe.
    private(set) var seq = -1
    /// Days back from today on Home (0 = today).
    private(set) var dayOffset = 0
    /// How far back Home can go (the earliest banked day).
    private(set) var maxDayOffset = 0
    private(set) var home: HomeSnapshot?
    private(set) var recovery: RecoverySnapshot?
    private(set) var strain: StrainSnapshot?
    private(set) var sleep: SleepSnapshot?
    private(set) var health: HealthSnapshot?
    /// Bumped whenever the display preferences change, so detail screens reload.
    private(set) var prefsVersion = 0

    /// The key a detail screen's `.task(id:)` reloads on.
    var detailKey: String { "\(seq)|\(dayOffset)|\(prefsVersion)" }
    /// The Health tab's reload key: it is always today, so Home's day does not enter it.
    var healthKey: String { "\(seq)|\(prefsVersion)" }

    // MARK: Dependencies (not observed)

    @ObservationIgnored private weak var repo: Repository?
    @ObservationIgnored private weak var profile: ProfileStore?
    @ObservationIgnored private weak var ble: BLEManager?
    @ObservationIgnored private var builder: PulseSnapshotBuilder?
    @ObservationIgnored private var prefs = PulsePrefs()
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var homeTask: Task<Void, Never>?
    @ObservationIgnored private var sleepTask: Task<Void, Never>?
    /// A day to open on once the history's extent is known (DEBUG `--pulse-day`).
    @ObservationIgnored private var pendingDayOffset: Int?

    /// Wire the model to the app's repository once. Later calls are ignored.
    func attach(repo: Repository, profile: ProfileStore, ble: BLEManager) {
        guard self.repo == nil else { return }
        self.repo = repo
        self.profile = profile
        self.ble = ble
        builder = PulseSnapshotBuilder(repo: repo)
        #if DEBUG
        pendingDayOffset = PulseDebugLaunch.dayOffset
        #endif
        // `@Published` emits in willSet, before `refreshSeq` itself changes (every cache is already
        // assigned by then, see `Repository.refresh`). Rebuild on the next turn so the request reads a
        // settled repository.
        repo.$refreshSeq
            .removeDuplicates()
            .sink { [weak self] value in
                Task { @MainActor [weak self] in self?.refreshChanged(to: value) }
            }
            .store(in: &cancellables)
        // A new HR max or sex re-scores Effort; debounced so typing into a profile field is one rebuild.
        profile.objectWillChange
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.invalidateAll() }
            }
            .store(in: &cancellables)
        refreshChanged(to: repo.refreshSeq)
    }

    /// Apply the display preferences the builder formats with.
    func updatePrefs(_ new: PulsePrefs) {
        guard new != prefs else { return }
        prefs = new
        prefsVersion &+= 1
        invalidateAll()
    }

    private func refreshChanged(to value: Int) {
        seq = value
        updateMaxOffset()
        if let pending = pendingDayOffset, maxDayOffset >= pending {
            dayOffset = pending
            pendingDayOffset = nil
        }
        rebuildHome()
    }

    /// Everything is stale: rebuild Home now; the open detail screen reloads through `detailKey`.
    private func invalidateAll() {
        updateMaxOffset()
        rebuildHome()
    }

    /// The app came back to the foreground: the logical day may have rolled and today's live strain has
    /// moved, even when no refresh has landed yet.
    func sceneBecameActive() {
        updateMaxOffset()
        rebuildHome()
    }

    /// Something outside a repository refresh may have changed what Home shows (a sheet closed after a
    /// journal entry or a logged workout, neither of which bumps `refreshSeq`): rebuild Home.
    func homeMayHaveChanged() {
        rebuildHome()
    }

    private func updateMaxOffset() {
        guard let repo else { return }
        maxDayOffset = LiquidTodayView.maxDayOffset(earliestDayKey: repo.freshness.earliestDay,
                                                    todayKey: Repository.logicalDayKey(Date()))
        if dayOffset > maxDayOffset { dayOffset = maxDayOffset }
    }

    // MARK: Day navigation

    /// Step `delta` days (+1 = one day older), clamped to today and the earliest banked day.
    func stepDay(_ delta: Int) {
        setDayOffset(dayOffset + delta)
    }

    func setDayOffset(_ offset: Int) {
        let clamped = min(max(0, offset), maxDayOffset)
        guard clamped != dayOffset else { return }
        dayOffset = clamped
        rebuildHome()
    }

    /// The logical day a date picked in the calendar falls on, as an offset.
    func pick(date: Date) {
        setDayOffset(LiquidTodayView.pickedDayOffset(pickedDate: date,
                                                     anchorLogicalDay: Repository.logicalDay(Date())))
    }

    /// The logical day Home is on, for the calendar picker's selection.
    var selectedLogicalDate: Date {
        let logical = Repository.logicalDay(Date())
        return Calendar.current.date(byAdding: .day, value: -dayOffset, to: logical) ?? logical
    }

    /// The earliest date the calendar may pick.
    var earliestLogicalDate: Date {
        let logical = Repository.logicalDay(Date())
        return Calendar.current.date(byAdding: .day, value: -maxDayOffset, to: logical) ?? logical
    }

    /// True while Home shows a snapshot for a different day than the one selected (a build is running).
    var homeIsStale: Bool {
        guard let home else { return true }
        return home.day.offset != dayOffset
    }

    // MARK: Requests

    /// Capture everything a build reads, in one main-actor pass.
    private func request(dayOffset: Int) -> PulseRequest? {
        guard let repo, let profile else { return nil }
        let now = Date()
        let logical = Repository.logicalDay(now)
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: logical) ?? logical
        // Today follows the repository's resolved today row (its pre-04:00 carve-out included), exactly
        // as the Liquid Today keys its reads; any other day is its own calendar key.
        let key = dayOffset == 0
            ? (repo.today?.day ?? Repository.localDayKey(date))
            : Repository.localDayKey(date)
        return PulseRequest(
            seq: seq,
            day: PulseDay(offset: dayOffset, key: key, date: date),
            now: now,
            days: repo.days,
            sleeps: repo.sleeps,
            importedSleep: repo.importedSleep,
            vitalRows: repo.vitalMetricRows,
            prefs: prefs,
            profile: PulseProfile(effortHRmax: profile.effortHRmax, sex: profile.sex,
                                  zoneSet: profile.hrZoneSet))
    }

    // MARK: Builds

    private func rebuildHome() {
        homeTask?.cancel()
        guard let builder, let req = request(dayOffset: dayOffset) else { return }
        homeTask = Task { [weak self] in
            let snapshot = await builder.home(req)
            guard let self, !Task.isCancelled, let snapshot,
                  snapshot.seq == self.seq, snapshot.day.offset == self.dayOffset else { return }
            if self.home != snapshot { self.home = snapshot }
        }
    }

    /// Build the Recovery dive for the selected day. Called from the screen's `.task(id: detailKey)`.
    func loadRecovery() async {
        guard let builder, let req = request(dayOffset: dayOffset) else { return }
        guard let snapshot = await builder.recovery(req), !Task.isCancelled,
              snapshot.seq == seq, snapshot.day.offset == dayOffset else { return }
        if recovery != snapshot { recovery = snapshot }
    }

    /// Build the Strain dive for the selected day.
    func loadStrain() async {
        guard let builder, let req = request(dayOffset: dayOffset) else { return }
        guard let snapshot = await builder.strain(req), !Task.isCancelled,
              snapshot.seq == seq, snapshot.day.offset == dayOffset else { return }
        if strain != snapshot { strain = snapshot }
    }

    /// Build the Health tab (always today).
    func loadHealth() async {
        guard let builder, let req = request(dayOffset: 0) else { return }
        guard let snapshot = await builder.health(req), !Task.isCancelled, snapshot.seq == seq else { return }
        if health != snapshot { health = snapshot }
    }

    /// Open the Sleep dive on the night that ended on Home's selected day.
    func openSleep() async {
        guard let builder, let req = request(dayOffset: dayOffset) else { return }
        let index = await builder.nightIndex(for: req)
        guard !Task.isCancelled else { return }
        // A snapshot left from an earlier visit may be another night: show loading, not the wrong night.
        if sleep?.nightIndex != index || sleep?.seq != seq { sleep = nil }
        await loadSleep(nightIndex: index)
    }

    /// Step the Sleep dive `delta` nights (+1 = one night older).
    func stepNight(_ delta: Int) {
        guard let current = sleep else { return }
        let target = current.nightIndex + delta
        guard target >= 0, target < current.nightCount else { return }
        sleepTask?.cancel()
        sleepTask = Task { [weak self] in await self?.loadSleep(nightIndex: target) }
    }

    /// Reload the Sleep dive on its current night (a refresh landed).
    func reloadSleep() async {
        if let current = sleep {
            await loadSleep(nightIndex: current.nightIndex)
        } else {
            await openSleep()
        }
    }

    private func loadSleep(nightIndex: Int) async {
        guard let builder, let req = request(dayOffset: dayOffset) else { return }
        guard let snapshot = await builder.sleep(req, nightIndex: nightIndex), !Task.isCancelled,
              snapshot.seq == seq else { return }
        if sleep != snapshot { sleep = snapshot }
    }

    // MARK: Refresh

    /// Pull-to-refresh: ask the strap for its history when it can answer (the same gate the Liquid
    /// Today's pull uses), re-read the store, and rebuild Home even when nothing in the caches changed,
    /// because today's live strain moves with every new heart-rate sample.
    func pullToRefresh() async {
        if let ble, ble.state.historyReady { ble.syncNow() }
        await repo?.refresh()
        rebuildHome()
    }

    /// A tab re-tap: re-read the store (the classic shell's reselect convention).
    func refresh() async {
        await repo?.refresh()
    }
}
#endif
