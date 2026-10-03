#if os(iOS)
import SwiftUI
import StrandAnalytics

/// The expanded day heart-rate timeline (WHOOP_UI_SPEC §3.7), presented full screen from ⤢ on TODAY'S
/// ACTIVITIES, or by turning the phone on Home (tilt mode, `pulseDayTimelineOnTilt()`).
///
/// Landscape-first, as WHOOP's: turned sideways it fills the screen with a top bar ("✕ HEART RATE",
/// "‹ TODAY ›", "Data synced to 07:44"), a label strip (moon and time asleep over the night, RECOVERY at
/// wake, STRAIN at the newest reading) and the plot (help-center/106, reviews/r132,
/// activity-flows-2026/e04). Held upright it keeps the same pieces stacked for a portrait screen, with the
/// day's low / average / high under the plot and a nudge to turn the phone. The data is the existing
/// full-day heart-rate read (the classic Deep Timeline's), over the window Home scores the day's Strain on.
///
/// Owned by group "extras".
struct PulseDayTimelineView: View {
    /// Rebuilt: Home's ⤢ opens this instead of the classic full-day chart.
    static let isRebuilt = true

    /// Opened by tilting the phone on Home: closes itself when the phone turns upright again.
    let closesWhenUpright: Bool

    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var monitor = PulseTiltMonitor()
    /// Days back from today; starts on Home's day, then steps on its own (closing returns Home unchanged).
    @State private var dayOffset: Int?
    @State private var snapshot: DayTimelineSnapshot?
    @State private var zoomed = false
    @State private var scroll: CGFloat = 0
    @State private var cursor: Date?

    private typealias T = PulseExtrasTheme.Timeline

    init(closesWhenUpright: Bool = false) {
        self.closesWhenUpright = closesWhenUpright
    }

    var body: some View {
        GeometryReader { outer in
            let insets = outer.safeAreaInsets
            GeometryReader { full in
                let size = full.size
                Group {
                    if monitor.orientation.isLandscape {
                        // The interface stays portrait; the timeline turns itself to read upright.
                        let side = insets.bottom > 0 ? insets.top : 0
                        let bottom: CGFloat = insets.bottom > 0 ? 21 : 0
                        let turned = CGSize(width: size.height, height: size.width)
                        landscape(size: turned, side: side, bottom: bottom)
                            .frame(width: turned.width, height: turned.height)
                            .rotationEffect(monitor.orientation.contentRotation)
                            .frame(width: size.width, height: size.height)
                            .transition(.opacity)
                    } else {
                        portrait(size: size, insets: insets)
                            .frame(width: size.width, height: size.height)
                            .transition(.opacity)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .background(PulseBackground())
        .animation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion),
                   value: monitor.orientation)
        .statusBarHidden(monitor.orientation.isLandscape)
        .persistentSystemOverlays(monitor.orientation.isLandscape ? .hidden : .automatic)
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.colorScheme, .dark)
        .onAppear {
            if dayOffset == nil { dayOffset = model.dayOffset }
            monitor.start()
        }
        .onDisappear { monitor.stop() }
        .onChange(of: monitor.orientation) { _, orientation in
            // The plot changes width, so a zoom or cursor from the other layout would land elsewhere.
            zoomed = false
            scroll = 0
            cursor = nil
            if closesWhenUpright && orientation == .portrait { dismiss() }
        }
        .task(id: loadKey) { await load() }
    }

    // MARK: Data

    private var loadKey: String {
        "\(model.seq)|\(model.prefsVersion)|\(dayOffset ?? -1)"
    }

    private func load() async {
        guard let offset = dayOffset else { return }
        if let s = await model.build(dayOffset: offset, { builder, request in await builder.dayTimeline(request) }),
           s.day.offset == dayOffset {
            snapshot = s
        }
    }

    private var canGoBack: Bool { (dayOffset ?? 0) < model.maxDayOffset }
    private var canGoForward: Bool { (dayOffset ?? 0) > 0 }

    private func step(_ delta: Int) {
        let next = min(max(0, (dayOffset ?? 0) + delta), model.maxDayOffset)
        guard next != dayOffset else { return }
        dayOffset = next
        // The chart on screen is another day's: clear it rather than show it under this day's title.
        snapshot = nil
        zoomed = false
        scroll = 0
        cursor = nil
    }

    private var dayTitle: String {
        let offset = dayOffset ?? 0
        let logical = Repository.logicalDay(Date())
        let date = Calendar.current.date(byAdding: .day, value: -offset, to: logical) ?? logical
        return PulseFormat.navDayTitle(offset: offset, date: date)
    }

    /// "Data synced to 7:44 AM" on today; nothing on a finished day.
    private var syncText: String? {
        guard let snapshot, snapshot.day.isToday else { return nil }
        guard let last = snapshot.lastReading else { return String(localized: "No heart rate synced yet") }
        return String(localized: "Data synced to \(PulseFormat.clock(last))")
    }

    // MARK: Zoom

    /// How far ⊕ magnifies this day: a third of the span, never under two hours in view; nil when the day
    /// is too short to zoom.
    private func zoomFactor(_ snapshot: DayTimelineSnapshot) -> CGFloat? {
        let span = snapshot.end.timeIntervalSince(snapshot.start)
        let factor = min(T.zoomFactor, CGFloat(span / T.minimumZoomedSpan))
        return factor >= 1.5 ? factor : nil
    }

    private func zoom(for snapshot: DayTimelineSnapshot) -> CGFloat {
        zoomed ? (zoomFactor(snapshot) ?? 1) : 1
    }

    private func toggleZoom(plot: CGRect) {
        guard let snapshot, let factor = zoomFactor(snapshot) else { return }
        cursor = nil
        if zoomed {
            zoomed = false
            scroll = 0
            return
        }
        zoomed = true
        let g = DayTimelineGeometry(plot: plot, start: snapshot.start, end: snapshot.end, zoom: factor)
        // Today opens on the newest hours, as WHOOP's does; a finished day on its middle.
        scroll = snapshot.day.isToday ? g.maxScroll : g.maxScroll / 2
    }

    // MARK: Landscape

    private func landscape(size: CGSize, side: CGFloat, bottom: CGFloat) -> some View {
        let stripTop = T.barHeight + 1
        let plotTop = stripTop + T.stripHeight + 1
        let plotX = side + T.plotLeading
        let plot = CGRect(x: plotX, y: plotTop,
                          width: max(100, size.width - side - T.plotTrailing - plotX),
                          height: max(80, size.height - bottom - T.xLabelCentre - T.xLabelGap - plotTop))
        let strip = CGRect(x: 0, y: stripTop, width: size.width, height: T.stripHeight)
        let zoomY = DayTimelineGeometry(plot: plot, start: Date(), end: Date()).y(120)
        return ZStack(alignment: .topLeading) {
            LinearGradient(stops: PulseTheme.pageStops, startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [T.barTop, T.barBottom], startPoint: .top, endPoint: .bottom)
                .frame(width: size.width, height: T.barHeight)
            hairline(width: size.width).offset(y: T.barHeight)
            stripBackground(width: size.width).offset(y: stripTop)
            hairline(width: size.width).offset(y: stripTop + T.stripHeight)

            chart(plot: plot, strip: strip, size: size)

            PulseCloseButton { dismiss() }
                .position(x: side + T.closeCentre, y: T.barHeight / 2)
            Text(String(localized: "Heart rate"))
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .fixedSize()
                .frame(height: T.barHeight)
                .offset(x: side + T.closeCentre + T.titleGap)
                .accessibilityAddTraits(.isHeader)
            pager
                .position(x: size.width / 2, y: T.barHeight / 2)
            if let syncText {
                Text(syncText)
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: max(0, size.width / 2 - 110 - side - T.syncTrailing), height: T.barHeight,
                           alignment: .trailing)
                    .offset(x: size.width / 2 + 110)
            }
            zoomButton(plot: plot)
                .position(x: size.width - side - T.zoomCentre, y: zoomY)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    // MARK: Portrait

    private func portrait(size: CGSize, insets: EdgeInsets) -> some View {
        let margin = PulseTheme.Layout.pageMargin
        let navTop = insets.top + PulseTheme.Header.navBarTop
        let pagerTop = navTop + PulseTheme.Header.navBar
        let barBottom = pagerTop + 36 + 22
        let stripTop = barBottom + 1
        let plotTop = stripTop + T.stripHeight + 1
        let plotX = margin + T.plotLeading
        // Below the plot: its time labels, the hint row and the low / average / high card.
        let footer: CGFloat = 30 + 52 + 96 + 16
        let plotHeight = min(400, max(240, size.height - insets.bottom - footer - plotTop))
        let plot = CGRect(x: plotX, y: plotTop, width: size.width - plotX - margin, height: plotHeight)
        let strip = CGRect(x: 0, y: stripTop, width: size.width, height: T.stripHeight)
        return ZStack(alignment: .topLeading) {
            LinearGradient(stops: PulseTheme.pageStops, startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [T.barTop, T.barBottom], startPoint: .top, endPoint: .bottom)
                .frame(width: size.width, height: barBottom)
            hairline(width: size.width).offset(y: barBottom)
            stripBackground(width: size.width).offset(y: stripTop)
            hairline(width: size.width).offset(y: stripTop + T.stripHeight)

            chart(plot: plot, strip: strip, size: size)

            // The bar: "✕" at the left, the centred title, then the day pager and the sync line.
            ZStack {
                Text(String(localized: "Heart rate"))
                    .pulseText(.navTitle)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                HStack {
                    PulseCloseButton { dismiss() }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, margin)
            .frame(width: size.width, height: PulseTheme.Header.navBar)
            .offset(y: navTop)
            VStack(spacing: 2) {
                pager.frame(height: 36)
                Text(syncText ?? " ")
                    .pulseText(.secondary)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .lineLimit(1)
                    .accessibilityHidden(syncText == nil)
            }
            .frame(width: size.width)
            .offset(y: pagerTop)

            portraitFooter(plot: plot, width: size.width)
                .offset(y: plot.maxY + 30)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func portraitFooter(plot: CGRect, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "rotate.right")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(PulseTheme.textTertiary)
                    .accessibilityHidden(true)
                Text(String(localized: "Turn your phone sideways for the wide view."))
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                zoomButton(plot: plot)
            }
            .frame(minHeight: 44)
            if let snapshot, snapshot.hasHeartRate {
                stats(snapshot)
            }
        }
        .padding(.horizontal, PulseTheme.Layout.pageMargin)
        .frame(width: width, alignment: .leading)
    }

    /// The day's lowest, average and highest heart rate: the Strain dive's figures for the same window.
    private func stats(_ snapshot: DayTimelineSnapshot) -> some View {
        PulseCard {
            HStack(alignment: .top, spacing: 0) {
                stat(String(localized: "Lowest"), snapshot.lowest)
                stat(String(localized: "Average"), snapshot.average)
                stat(String(localized: "Highest"), snapshot.highest)
            }
        }
    }

    private func stat(_ title: String, _ value: Int?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            PulseLabel(title, color: PulseTheme.textTertiary)
            PulseValueText(value: value.map(String.init) ?? "--", unit: value == nil ? nil : "bpm",
                           style: .tileValue, unitStyle: .tileUnit)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Pieces

    @ViewBuilder
    private func chart(plot: CGRect, strip: CGRect, size: CGSize) -> some View {
        PulseLoadingGate(isLoading: snapshot == nil) {
            if let snapshot {
                DayTimelineChart(snapshot: snapshot, plot: plot, strip: strip, zoom: zoom(for: snapshot),
                                 scroll: $scroll, cursor: $cursor)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
            }
        } skeleton: {
            PulseSkeletonBlock(height: plot.height, width: plot.width, radius: PulseTheme.Radius.well)
                .offset(x: plot.minX, y: plot.minY)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .accessibilityLabel(String(localized: "Loading"))
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }

    private func hairline(width: CGFloat) -> some View {
        T.hairline.frame(width: width, height: 1).accessibilityHidden(true)
    }

    /// The label strip: #16191E, fading in from the page over its first 60 pt.
    private func stripBackground(width: CGFloat) -> some View {
        LinearGradient(stops: [
            .init(color: T.strip.opacity(0), location: 0),
            .init(color: T.strip, location: min(1, T.stripFade / max(width, 1)))
        ], startPoint: .leading, endPoint: .trailing)
        .frame(width: width, height: T.stripHeight)
        .accessibilityHidden(true)
    }

    /// "‹ TODAY ›": steps the day this timeline shows.
    private var pager: some View {
        HStack(spacing: 0) {
            pagerChevron("chevron.left", enabled: canGoBack, label: String(localized: "Previous day")) { step(1) }
            Text(dayTitle)
                .pulseText(.navTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 6)
                .accessibilityAddTraits(.isHeader)
            pagerChevron("chevron.right", enabled: canGoForward, label: String(localized: "Next day")) { step(-1) }
        }
    }

    private func pagerChevron(_ symbol: String, enabled: Bool, label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? PulseTheme.textPrimary : PulseTheme.textDisabled)
                .frame(width: 36, height: PulseTheme.Layout.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func zoomButton(plot: CGRect) -> some View {
        if let snapshot, snapshot.hasHeartRate, zoomFactor(snapshot) != nil {
            Button { toggleZoom(plot: plot) } label: {
                Image(systemName: zoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(zoomed ? String(localized: "Zoom out") : String(localized: "Zoom in"))
            .accessibilityHint(zoomed ? "" : String(localized: "Drag to move through the day; hold to read a value."))
        }
    }
}
#endif
