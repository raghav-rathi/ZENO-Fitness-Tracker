#if os(iOS)
import SwiftUI
import Charts
import MapKit
import StrandAnalytics
import WhoopStore
import WhoopProtocol

/// The live session (WHOOP_UI_SPEC §3.8 "Live session"): a full-screen pager under a blue band holding the
/// elapsed time, the pause / resume control [Z] and the flag that ends it. [Heart Rate] ← [Activity Strain]
/// → [Map], the map only for a session recording a route; the pager opens on Activity Strain.
///
/// Every figure is the engine's own: `AppModel.activeWorkout` (its samples, Strain, average and peak) and the
/// smoothed live `bpm`, the zones of the wearer's profile, `GpsWorkoutRecorder`'s distance and route.
/// Strain is shown on the 0–21 scale (the classic screen defaulted to Effort 0–100). End & Save goes through
/// `endWorkout`, Discard through `discardWorkout`.
struct PulseLiveSessionView: View {
    /// Called after End & Save with the row the engine saved, or nil when it kept nothing.
    let onFinish: (WorkoutRow?) -> Void
    /// Called after Discard.
    let onDiscard: () -> Void

    @EnvironmentObject private var app: AppModel
    @AppStorage("workoutKeepScreenOn") private var keepScreenOn = false
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceSystemRaw = ""

    @State private var page: Page = .strain
    @State private var endDialog: EndDialog?
    @State private var calories: Double?
    @State private var session: PulseActivitySessionStore.Session?

    enum Page: Hashable { case heartRate, strain, map }
    enum EndDialog: Identifiable {
        case end, discard
        var id: Self { self }
    }

    private var workout: AppModel.ActiveWorkout? { app.activeWorkout }
    private var kind: PulseActivityKind { PulseActivityCatalog.kind(named: workout?.sport ?? "") }
    /// The session records a route: a distance sport whose Track Route stayed on.
    private var hasMap: Bool { kind.isDistanceSport && (session?.trackRoute ?? true) }
    /// The session's Activity Strain, 0–21.
    private var strain: Double { UnitFormatter.effortValue(workout?.liveStrain ?? 0, scale: .whoop) }
    private var zoneSet: HRZoneSet { app.profile.hrZoneSet }
    private var zone: Int? { app.bpm.map { zoneSet.zoneNumber(forBPM: Double($0)) } }
    private var distanceSystem: UnitSystem {
        UnitPrefs.resolveDistance(system: UnitSystem(rawValue: unitSystemRaw) ?? .metric, override: distanceSystemRaw)
    }

    private var pages: [Page] { hasMap ? [.heartRate, .strain, .map] : [.heartRate, .strain] }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                band(safeTop: geo.safeAreaInsets.top)
                TabView(selection: $page) {
                    heartRatePage.tag(Page.heartRate)
                    strainPage(height: geo.size.height - 81 - 44).tag(Page.strain)
                    if hasMap {
                        PulseLiveMapPage(recorder: app.gpsRecorder, start: workout?.start, isPaused: workout?.isPaused ?? false,
                                         elapsed: { workout?.elapsed() ?? 0 }, system: distanceSystem,
                                         showsPace: kind.name.lowercased().contains("run"))
                            .tag(Page.map)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                footer
                    .padding(.bottom, max(4, geo.safeAreaInsets.bottom - 18))
            }
            .ignoresSafeArea(edges: [.top, .bottom])
        }
        .background(LinearGradient(gradient: PulseTheme.Gradients.liveSession, startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .onAppear(perform: appear)
        .onDisappear {
            app.stopRealtimeHR()
            ScreenIdle.keepAwake(false)
        }
        .task(id: (workout?.samples.count ?? 0) / 10) { await estimateCalories() }
        .fullScreenCover(item: $endDialog) { dialog in
            switch dialog {
            case .end:
                PulseDialogCard(title: String(localized: "End this activity?"),
                                message: String(localized: "This stops recording and saves what's captured so far."),
                                primaryTitle: String(localized: "End & Save"),
                                primary: { endDialog = nil; endAndSave() },
                                secondaryTitle: String(localized: "Discard"),
                                secondary: { endDialog = .discard },
                                onClose: { endDialog = nil })
                    .presentationBackground(.clear)
            case .discard:
                PulseDialogCard(title: String(localized: "Discard this activity?"),
                                message: String(localized: "Nothing from this session is saved. This can't be undone."),
                                primaryTitle: String(localized: "Keep recording"),
                                primary: { endDialog = nil },
                                secondaryTitle: String(localized: "Discard"),
                                secondary: { endDialog = nil; discard() },
                                onClose: { endDialog = nil })
                    .presentationBackground(.clear)
            }
        }
    }

    // MARK: Lifecycle

    private func appear() {
        // Arm the realtime stream while the session is on screen (WHOOP 5/MG only stream it on request),
        // and hold the screen awake if the wearer asked for that (LiveWorkoutView's contract).
        app.startRealtimeHR()
        if keepScreenOn { ScreenIdle.keepAwake(true) }
        if let start = workout?.start {
            session = PulseActivitySessionStore.session(startSec: Int(start.timeIntervalSince1970))
        }
        enforceTrackRoute()
        #if DEBUG
        if let minutes = PulseActivityDebug.demoLiveMinutes, let w = workout {
            let count = w.samples.count
            if count > minutes * 30, let last = w.samples.last { app.bpm = last.bpm }
        }
        switch PulseActivityDebug.livePage {
        case "hr": page = .heartRate
        case "map": page = .map
        default: break
        }
        if PulseActivityDebug.has("--activity-end-dialog") { endDialog = .end }
        if PulseActivityDebug.has("--activity-end-save") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { endAndSave() }
        }
        #endif
    }

    /// Track Route switched off for a sport that records one: keep the recorder stopped, including after a
    /// resume or a relaunch re-arms it.
    private func enforceTrackRoute() {
        if session?.trackRoute == false, app.gpsRecorder.isRecording { app.gpsRecorder.stop() }
    }

    private func togglePause() {
        app.toggleWorkoutPause()
        enforceTrackRoute()
    }

    private func endAndSave() {
        app.endWorkout()
        PulseActivitySessionStore.clear()
        onFinish(app.lastWorkout)
    }

    private func discard() {
        app.discardWorkout()
        PulseActivitySessionStore.clear()
        onDiscard()
    }

    /// The calories the session would save with: the engine's own model over the samples so far
    /// (`Calories.estimateBoutCalories`, as `endWorkout` scores it), off the main actor.
    private func estimateCalories() async {
        guard let w = workout, w.samples.count >= 2 else { calories = nil; return }
        let samples = w.samples
        let profile = app.profile
        let up = UserProfile(weightKg: profile.weightKg, heightCm: profile.heightCm, age: Double(profile.age),
                             sex: profile.sex)
        let hrMax = Double(profile.hrMax)
        let resting = app.repo.today?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR
        let kcal = await Task.detached(priority: .utility) {
            Calories.estimateBoutCalories(samples, profile: up, hrmax: hrMax, restingHR: resting).0
        }.value
        calories = kcal > 0 ? kcal : 0
    }

    // MARK: Band

    /// The blue band (§3.8): ❚❚ / ▶ [Z], the flag that ends the session, and the elapsed time.
    private func band(safeTop: CGFloat) -> some View {
        HStack(spacing: 14) {
            Spacer(minLength: 0)
            Button(action: togglePause) {
                Image(systemName: workout?.isPaused == true ? "play.fill" : "pause.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.22)))
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(workout?.isPaused == true ? String(localized: "Resume") : String(localized: "Pause"))
            Button { endDialog = .end } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 18, weight: .semibold))
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(ActivityFormat.paddedClock(seconds: workout?.elapsed() ?? 0))
                            .font(PulseType.numeral(22))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(Color.white)
                .frame(minHeight: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "End activity"))
            .accessibilityValue(ActivityFormat.paddedClock(seconds: workout?.elapsed() ?? 0))
            .accessibilityHint(String(localized: "Ends and saves the activity"))
            Spacer(minLength: 0)
            // Balances the pause control so the clock stays centred.
            Color.clear.frame(width: PulseTheme.Layout.minTapTarget, height: 1)
        }
        .padding(.top, safeTop + 14)
        .padding(.bottom, 23)
        .frame(maxWidth: .infinity)
        .background(PulseTheme.Activity.liveBand)
        .overlay(alignment: .bottom) {
            if workout?.isPaused == true {
                Text(String(localized: "Paused"))
                    .pulseText(.label)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.bottom, 4)
            }
        }
    }

    // MARK: Activity Strain page

    private func strainPage(height: CGFloat) -> some View {
        let ring = min(290, max(200, height * 0.4))
        return VStack(spacing: 0) {
            Spacer(minLength: 24).frame(maxHeight: 89)
            PulseLiveStrainRing(strain: strain, target: session?.target, diameter: ring,
                                avatar: app.profile.avatarImageData)
            Spacer(minLength: 20).frame(maxHeight: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Heart rate"))
                    .pulseText(.cardTitle)
                    .foregroundStyle(PulseTheme.textTertiary)
                Text(app.bpm.map { "\($0)" } ?? "--")
                    .font(PulseType.font(.largeValue))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .accessibilityLabel(String(localized: "Heart rate"))
                    .accessibilityValue(app.bpm.map { String(localized: "\($0) beats per minute") } ?? String(localized: "No reading"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            PulseLiveZoneBar(zone: zone, bpm: app.bpm.map(Double.init), zoneSet: zoneSet)
                .padding(.horizontal, 10)
                .padding(.top, 14)
            Spacer(minLength: 16).frame(maxHeight: 42)
            HStack(spacing: 0) {
                statColumn(icon: "heart.fill", title: String(localized: "Avg HR"),
                           value: (workout?.avgHr ?? 0) > 0 ? "\(workout?.avgHr ?? 0)" : "--")
                hairline
                statColumn(icon: "arrow.up.heart.fill", title: String(localized: "Max HR"),
                           value: (workout?.peakHr ?? 0) > 0 ? "\(workout?.peakHr ?? 0)" : "--")
                hairline
                statColumn(icon: "flame.fill", title: String(localized: "Calories"),
                           value: calories.map(PulseFormat.grouped) ?? "--")
            }
            .padding(.horizontal, 10)
            Spacer(minLength: 0)
        }
    }

    private func statColumn(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
                .frame(height: 24)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(PulseType.font(.largeValue))
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var hairline: some View {
        Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 96)
    }

    // MARK: Heart Rate page

    private var heartRatePage: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(Color.black)
                VStack(spacing: 0) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 17, weight: .regular))
                    Text(app.bpm.map { "\($0)" } ?? "--")
                        .font(PulseType.numeral(44))
                    Text(zone.map { String(localized: "Zone \($0)") } ?? String(localized: "No reading"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulseTheme.textSecondary)
                }
                .foregroundStyle(PulseTheme.textPrimary)
            }
            .frame(width: 132, height: 132)
            .padding(.top, 40)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: "Heart rate"))
            .accessibilityValue(app.bpm.map { String(localized: "\($0) beats per minute") } ?? String(localized: "No reading"))
            Spacer(minLength: 20)
            PulseLiveHRCurve(samples: workout?.samples ?? [])
                .frame(height: 230)
            Spacer(minLength: 20)
            HStack(spacing: 0) {
                statColumn(icon: "heart.fill", title: String(localized: "Avg HR"),
                           value: (workout?.avgHr ?? 0) > 0 ? "\(workout?.avgHr ?? 0)" : "--")
                hairline
                statColumn(icon: "figure.strengthtraining.traditional", title: String(localized: "Strain"),
                           value: PulseFormat.oneDecimal(strain))
                hairline
                statColumn(icon: "flame.fill", title: String(localized: "Calories"),
                           value: calories.map(PulseFormat.grouped) ?? "--")
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
    }

    // MARK: Footer

    /// "← Heart Rate" · page dots · "Map →".
    private var footer: some View {
        let index = pages.firstIndex(of: page) ?? 1
        let previous = index > 0 ? pages[index - 1] : nil
        let next = index + 1 < pages.count ? pages[index + 1] : nil
        return HStack {
            footerLink(previous, leading: true)
            Spacer(minLength: 8)
            HStack(spacing: 9) {
                ForEach(pages, id: \.self) { p in
                    Circle()
                        .fill(p == page ? PulseTheme.textPrimary : PulseTheme.textTertiary.opacity(0.6))
                        .frame(width: 7, height: 7)
                }
            }
            .accessibilityHidden(true)
            Spacer(minLength: 8)
            footerLink(next, leading: false)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
    }

    @ViewBuilder
    private func footerLink(_ target: Page?, leading: Bool) -> some View {
        if let target {
            Button { page = target } label: {
                HStack(spacing: 4) {
                    if leading { Image(systemName: "arrow.left").font(.system(size: 12, weight: .regular)) }
                    Text(title(target))
                    if !leading { Image(systemName: "arrow.right").font(.system(size: 12, weight: .regular)) }
                }
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(minWidth: 110, minHeight: PulseTheme.Layout.minTapTarget, alignment: leading ? .leading : .trailing)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        } else {
            Color.clear.frame(width: 110, height: 1)
        }
    }

    private func title(_ page: Page) -> String {
        switch page {
        case .heartRate: return String(localized: "Heart Rate")
        case .strain: return String(localized: "Activity Strain")
        case .map: return String(localized: "Map")
        }
    }
}

// MARK: - The live Strain ring (§2.5 "Live Activity Strain ring")

/// ≈290 pt, an 18 pt stroke: the arc from 12 o'clock in the navy → blue gradient, brightest at its head;
/// the track lighter from the head round to the session's target (b01–b04), the wearer's avatar on the
/// ring at the target with a white tick; in the middle ACTIVITY STRAIN, the value and its intensity word.
struct PulseLiveStrainRing: View {
    let strain: Double
    /// The Activity Strain target (0–21), when the session has one.
    let target: Double?
    var diameter: CGFloat = 290
    var avatar: Data?

    private let stroke: CGFloat = 18

    var body: some View {
        let fraction = max(0, min(1, strain / 21))
        let targetFraction = target.map { max(0, min(1, $0 / 21)) }
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.045), lineWidth: stroke)
            if let targetFraction, targetFraction > fraction {
                PulseRingSegment(start: fraction, end: targetFraction, thickness: stroke, cornerRadius: 0)
                    .fill(PulseTheme.Activity.liveRingTrack)
            }
            if fraction > 0 {
                PulseRingSegment(start: 0, end: fraction, thickness: stroke, cornerRadius: 0,
                                 minimumLength: PulseTheme.Dial.minimumArc)
                    .fill(AngularGradient(gradient: PulseTheme.Activity.liveRingArc, center: .center,
                                          startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * fraction)))
            }
            if let targetFraction {
                PulseRingTick(fraction: targetFraction, thickness: stroke)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2))
                PulseAvatar(imageData: avatar, name: nil, size: 22)
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 1.5))
                    .offset(knobOffset(targetFraction))
            }
            VStack(spacing: 4) {
                Text(String(localized: "Activity Strain"))
                    .font(.system(size: 15, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(PulseFormat.oneDecimal(strain))
                    .font(PulseType.font(.liveStrain))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .pulseNumericTransition()
                    .padding(.vertical, -6)
                Text(ActivityFormat.intensity(activityStrain: strain))
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.3)
                    .textCase(.uppercase)
                    .foregroundStyle(PulseTheme.textTertiary)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Activity Strain"))
        .accessibilityValue([String(localized: "\(PulseFormat.oneDecimal(strain)) out of 21"),
                             ActivityFormat.intensity(activityStrain: strain),
                             target.map { String(localized: "target \(PulseFormat.oneDecimal($0))") }]
            .compactMap { $0 }.joined(separator: ", "))
    }

    /// The knob sits on the inner edge of the ring at the target.
    private func knobOffset(_ fraction: Double) -> CGSize {
        let r = diameter / 2 - stroke - 6
        let angle = fraction * 2 * .pi - .pi / 2
        return CGSize(width: r * CGFloat(cos(angle)), height: r * CGFloat(sin(angle)))
    }
}

// MARK: - The live zone bar (§2.5 "Live HR zone bar")

/// Six segments, Zone 0 → Zone 5: the current one lit in its colour with a white dot where the heart rate
/// sits inside it, the others dark tints; "Zone 0" … "Zone 5" under them, the current one white.
struct PulseLiveZoneBar: View {
    let zone: Int?
    let bpm: Double?
    let zoneSet: HRZoneSet

    /// Where `bpm` sits inside its zone, 0...1.
    private var position: Double {
        guard let zone, let bpm else { return 0.5 }
        let zones = zoneSet.zones
        if zone == 0 {
            let top = zones.first(where: { $0.number == 1 })?.lower ?? 100
            let bottom = max(30, top - 40)
            return max(0, min(1, (bpm - bottom) / (top - bottom)))
        }
        guard let z = zones.first(where: { $0.number == zone }) else { return 0.5 }
        let upper = zone == 5 ? zoneSet.maxHR : z.upper
        return max(0, min(1, (bpm - z.lower) / max(1, upper - z.lower)))
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 1.5) {
                ForEach(0...5, id: \.self) { z in
                    let active = z == zone
                    Rectangle()
                        .fill(active ? PulseTheme.Zone.color(z) : PulseTheme.Zone.dimmed(z))
                        .frame(height: 5)
                        .overlay(alignment: .leading) {
                            if active {
                                GeometryReader { geo in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .position(x: geo.size.width * position, y: geo.size.height / 2)
                                }
                            }
                        }
                }
            }
            HStack(spacing: 1.5) {
                ForEach(0...5, id: \.self) { z in
                    Text(String(localized: "Zone \(z)"))
                        .font(.system(size: 13, weight: z == zone ? .bold : .semibold))
                        .foregroundStyle(z == zone ? PulseTheme.textPrimary : PulseTheme.Zone.color(z).opacity(0.38))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart-rate zone"))
        .accessibilityValue(zone.map { String(localized: "Zone \($0)") } ?? String(localized: "No reading"))
    }
}

// MARK: - The live heart-rate curve

/// The session's heart rate as an area, full width (the Heart Rate page).
struct PulseLiveHRCurve: View {
    let samples: [HRSample]

    private var points: [PulseTimeValue] {
        PulseSnapshotBuilder.displayPoints(samples)
    }

    var body: some View {
        let values = points.compactMap(\.value)
        let lo = (values.min() ?? 60) - 10, hi = (values.max() ?? 160) + 10
        Group {
            if values.count > 1 {
                Chart(points) { p in
                    if let v = p.value {
                        AreaMark(x: .value("Time", p.date), yStart: .value("Base", lo), yEnd: .value("BPM", v))
                            .foregroundStyle(LinearGradient(colors: [PulseTheme.strain.opacity(0.45), PulseTheme.strain.opacity(0.0)],
                                                            startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("Time", p.date), y: .value("BPM", v))
                            .foregroundStyle(PulseTheme.strain)
                            .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    }
                }
                .chartYScale(domain: lo...hi)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            } else {
                Text(String(localized: "Your heart rate draws here as the strap records it."))
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Heart rate this session"))
    }
}

// MARK: - The live map page (§3.8 "Map page")

/// A light map of the route so far (#0A8AF0, ≈5 pt) and the wearer's position, over the near-black stats
/// panel: DISTANCE | SPEED (or PACE) | DURATION. Its own leaf: it observes the GPS recorder.
struct PulseLiveMapPage: View {
    @ObservedObject var recorder: GpsWorkoutRecorder
    let start: Date?
    let isPaused: Bool
    let elapsed: () -> TimeInterval
    let system: UnitSystem
    let showsPace: Bool

    @State private var route: [CLLocationCoordinate2D] = []

    var body: some View {
        VStack(spacing: 0) {
            Map(initialPosition: .userLocation(fallback: .automatic)) {
                if route.count >= 2 {
                    MapPolyline(coordinates: route)
                        .stroke(PulseTheme.Activity.mapRoute, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
                UserAnnotation()
            }
            .mapStyle(.standard)
            .environment(\.colorScheme, .light)
            .overlay {
                if recorder.pointCount == 0 {
                    Text(isPaused ? String(localized: "Paused. The route resumes with the session.")
                                  : String(localized: "Waiting for a GPS fix…"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.white.opacity(0.9)))
                }
            }
            HStack(alignment: .top, spacing: 0) {
                stat(icon: "arrow.right", title: String(localized: "Distance"), value: distance.0, unit: distance.1)
                divider
                stat(icon: showsPace ? "speedometer" : "figure.walk",
                     title: showsPace ? String(localized: "Pace") : String(localized: "Speed"),
                     value: rate.0, unit: rate.1)
                divider
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let total = max(0, Int(elapsed()))
                    stat(icon: "stopwatch", title: String(localized: "Duration"),
                         value: String(format: "%d:%02d", total / 3600, (total % 3600) / 60), unit: "")
                }
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 10)
            .background(LinearGradient(gradient: PulseTheme.Activity.mapStatsPanel, startPoint: .top, endPoint: .bottom))
        }
        .onChange(of: recorder.pointCount, initial: true) { _, _ in
            guard let captured = recorder.capturedRoute() else { route = []; return }
            route = RouteMath.decode(captured.polyline).map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }
        }
    }

    private var distance: (String, String) {
        let km = recorder.distanceM / 1000
        let shown = system == .imperial ? km * UnitFormatter.milesPerKilometer : km
        return (PulseFormat.oneDecimal(shown), UnitFormatter.distanceUnit(system))
    }

    private var rate: (String, String) {
        guard let pace = recorder.paceSecPerKm, pace > 0 else { return ("--", "") }
        let perUnit = system == .imperial ? pace / UnitFormatter.milesPerKilometer : pace
        if showsPace {
            let total = Int(perUnit.rounded())
            return (String(format: "%d:%02d", total / 60, total % 60), "/\(UnitFormatter.distanceUnit(system))")
        }
        return (PulseFormat.oneDecimal(3600 / perUnit), system == .imperial ? "mph" : "km/h")
    }

    private var divider: some View {
        Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 76)
    }

    private func stat(icon: String, title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(PulseTheme.textTertiary)
            Text(title)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value).font(PulseType.numeral(28))
                if !unit.isEmpty { Text(unit).font(.system(size: 15, weight: .semibold)) }
            }
            .foregroundStyle(PulseTheme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value) \(unit)")
    }
}
#endif
