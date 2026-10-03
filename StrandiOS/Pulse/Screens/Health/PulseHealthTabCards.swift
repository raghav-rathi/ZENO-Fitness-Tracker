#if os(iOS)
import SwiftUI
import StrandAnalytics

// MARK: - The Health tab's cards (WHOOP_UI_SPEC §3.20)

/// "7.2 years younger" / "0.4 years older" / "About your age", from the engine's own gap.
func healthYearsLine(_ yearsYounger: Double) -> String {
    let amount = PulseFormat.oneDecimal(abs(yearsYounger))
    if amount == PulseFormat.oneDecimal(0) { return String(localized: "About your age") }
    return yearsYounger > 0 ? String(localized: "\(amount) years younger")
                            : String(localized: "\(amount) years older")
}

// MARK: Orb

/// The whole orb at rest (≈210 pt, health-more-2026/02 frame 94) with "34.5 / ZENO AGE / 7.2 years
/// younger"; scrolled, it passes under the pinned title and reads as a half sphere. Tap → Healthspan.
struct HealthAgeHero: View {
    let summary: HealthAgeSummary
    /// Whether the card after it (the Pace card, whose top is open) tucks up under the disc.
    var tucksNextCard = true

    /// How far the next card tucks under the hero (the stack's 24 pt gap plus the card's 16 pt padding
    /// would otherwise leave ≈45 pt between the disc and the PACE OF AGING caps).
    static let pullUp: CGFloat = -17

    var body: some View {
        PulseLink(.healthspan) {
            HealthAgeOrb(hue: summary.week.hue, diameter: 210) {
                HealthOrbReading(age: PulseFormat.oneDecimal(summary.week.zenoAge),
                                 yearsLine: healthYearsLine(summary.week.yearsYounger), hue: summary.week.hue)
            }
            // DEBUG `--pulse-scroll orbmid` lands here: the orb half under the title, as WHOOP shows it scrolled.
            .overlay { Color.clear.frame(width: 1, height: 1).id("pulse.orbmid") }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        // The Pace card rides up under the disc: its title caps sit ≈28 pt below it (health-more-2026/02
        // frame 94), the card's open top fading into the glow.
        .padding(.bottom, tucksNextCard ? HealthAgeHero.pullUp : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "ZENO Age \(PulseFormat.oneDecimal(summary.week.zenoAge)), \(healthYearsLine(summary.week.yearsYounger))"))
        .accessibilityHint(String(localized: "Opens Healthspan"))
    }
}

/// Before ZENO Age unlocks (health-more-2026/16, onboarding/32e): the dormant grey orb with magenta speckles
/// sitting in the top of a card whose violet-to-rose rim is open at the top, "UNLOCK ZENO AGE", how many
/// more nights it needs and a 4 pt magenta progress bar.
struct HealthUnlockHero: View {
    let nights: Int
    let needed: Int

    private static let orb: CGFloat = 166
    /// How far the orb dips into the card.
    private static let overlap: CGFloat = 54

    private var remaining: Int { max(0, needed - nights) }

    private var message: String {
        switch remaining {
        case 0: return String(localized: "Your ZENO Age arrives with this week's update.")
        case 1: return String(localized: "1 more night to unlock your personal ZENO Age.")
        default: return String(localized: "\(remaining) more nights to unlock your personal ZENO Age.")
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 14) {
                Text(String(localized: "Unlock ZENO Age"))
                    .pulseText(.menuLabel)
                    .foregroundStyle(PulseTheme.textPrimary)
                Text(message)
                    .pulseText(.subtitle)
                    .foregroundStyle(HealthPalette.unlockBody)
                    .fixedSize(horizontal: false, vertical: true)
                HealthProgressBar(fraction: needed > 0 ? Double(nights) / Double(needed) : 0)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, Self.overlap + 30)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(card)
            .padding(.top, Self.orb - Self.overlap)
            HealthAgeOrb(hue: .unlocking, diameter: Self.orb)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Unlock ZENO Age"))
        .accessibilityValue(String(localized: "\(nights) of \(needed) nights. \(message)"))
    }

    /// Fill and rim both fade out toward the top, so the orb sits in the card's open mouth.
    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        return ZStack {
            shape.fill(LinearGradient(colors: [PulseTheme.Gradients.healthUnlockCard.opacity(0),
                                               PulseTheme.Gradients.healthUnlockCard],
                                      startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5)))
            shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.healthUnlockBorder,
                                              startPoint: .leading, endPoint: .trailing), lineWidth: 1.5)
                .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.45)))
        }
    }
}

/// "Your Healthspan is calibrating…" (§3.20 item 2): the blue-tinted note with an hourglass and ✕, while
/// the 6-month window holds too few weeks for ZENO Age to have settled. Dismissed for the week.
struct HealthCalibratingNote: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "hourglass")
                .healthGlyph(.noteIcon)
                .foregroundStyle(HealthPalette.calibratingText)
                .padding(.top, 2)
                .accessibilityHidden(true)
            Text(String(localized: "Your Healthspan is calibrating, so fluctuations in your ZENO Age are normal. As ZENO collects more data, it will stabilize."))
                .pulseText(.rowText)
                .foregroundStyle(HealthPalette.calibratingText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .healthGlyph(.control)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: PulseTheme.Layout.minTapTarget, height: PulseTheme.Layout.minTapTarget,
                           alignment: .topTrailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Dismiss"))
        }
        .padding(.leading, 16)
        .padding(.vertical, 14)
        .padding(.trailing, 6)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(HealthPalette.calibratingFill))
    }
}

// MARK: Pace of Aging

/// PACE OF AGING with "▼ slower vs. last week" at the right, the ruler, and GO TO HEALTHSPAN. The card's
/// fill and rim fade out toward its top, so it opens into the glow above (reviews/r44).
struct HealthPaceCard: View {
    let summary: HealthAgeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Side by side when both fit; at the largest text sizes the chip drops under the title rather
            // than squeezing it to a word per line.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 8) {
                    PulseCardTitle(String(localized: "Pace of Aging"))
                        .fixedSize()
                    Spacer(minLength: 8)
                    chip
                }
                VStack(alignment: .leading, spacing: 8) {
                    PulseCardTitle(String(localized: "Pace of Aging"))
                    chip
                }
            }
            HealthPaceRuler(pace: summary.pace, combInset: 6)
            PulseLink(.healthspan) {
                Text(String(localized: "Go to Healthspan"))
            }
            .buttonStyle(.pulseNested)
            .padding(.top, 4)
        }
        .padding(16)
        .background(card)
    }

    @ViewBuilder
    private var chip: some View {
        if let change = summary.paceChange {
            HealthPaceChangeChip(change: change)
                .fixedSize()
        }
    }

    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
        return ZStack {
            shape.fill(LinearGradient(colors: [PulseTheme.card.opacity(0), PulseTheme.card.opacity(0.75)],
                                      startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(HealthPalette.paceCardRim, lineWidth: 1)
                .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4)))
        }
    }
}

/// "▼ slower vs. last week" (teal), "• no change vs. last week" (grey), "▲ faster vs. last week" (orange).
struct HealthPaceChangeChip: View {
    let change: PaceOfAging.Change

    var body: some View {
        switch change {
        case .slower:
            PulseDeltaChip(text: String(localized: "slower vs. last week"),
                           trend: PulseTrend(direction: .down, polarity: .lowerIsBetter))
        case .same:
            PulseDeltaChip(text: String(localized: "no change vs. last week"),
                           trend: PulseTrend(direction: .flat, polarity: .lowerIsBetter))
        case .faster:
            PulseDeltaChip(text: String(localized: "faster vs. last week"),
                           trend: PulseTrend(direction: .up, polarity: .lowerIsBetter))
        }
    }
}

// MARK: Lab Book

/// LAB BOOK › in the Advanced Labs slot (§3.20 item 4, §3.27 [Z]): what the book holds, by category, with
/// the newest reading's date, and a ring of segments shared out by category around the marker count. The
/// Lab Book never judges a value (its own promise), so the card counts and never says Optimal or Out of
/// Range, and the ring uses the neutral data blue. Empty: the add-your-results card. Opens the Lab Book.
struct HealthLabBookCard: View {
    let labs: HealthLabsSummary?

    var body: some View {
        PulseLink(.classic(.labBook)) {
            if let labs {
                filled(labs)
            } else {
                empty
            }
        }
        .buttonStyle(PulsePressStyle())
    }

    private func filled(_ labs: HealthLabsSummary) -> some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 14) {
                PulseCardTitle(String(localized: "Lab Book"), accessory: .trailingChevron)
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(labs.categories.prefix(3)) { category in
                            HStack(spacing: 8) {
                                PulseStatusChip(category.title, kind: .neutral)
                                    .lineLimit(1)
                                    .fixedSize()
                                Spacer(minLength: 4)
                                Text("\(category.markers)")
                                    .font(PulseType.font(.rowValue))
                                    .foregroundStyle(PulseTheme.textPrimary)
                            }
                        }
                        if let key = labs.lastUpdatedKey {
                            Text(String(localized: "Last updated: \(PulseFormat.dayLabel(key, template: "yMMMd"))"))
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    HealthLabRing(categories: labs.categories, total: labs.markers)
                        .frame(width: 140, height: 140)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Lab Book"))
        .accessibilityValue(String(localized: "\(labs.markers) markers, \(labs.readings) readings"))
        .accessibilityHint(String(localized: "Opens the Lab Book"))
    }

    private var empty: some View {
        // The title row spans the card, so its › sits at the top-right corner above the art
        // (health-more-2026/16), not at the end of the text column.
        VStack(alignment: .leading, spacing: 12) {
            PulseCardTitle(String(localized: "Lab Book"), accessory: .trailingChevron)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "Add your lab results from doctor visits to see them next to your 24/7 data."))
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(String(localized: "Add results")).pulseText(.label)
                        Image(systemName: "arrow.right").healthGlyph(.inlineArrow)
                    }
                    .foregroundStyle(PulseTheme.recoveryBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle()
                        .strokeBorder(PulseTheme.positive.opacity(0.7), style: StrokeStyle(lineWidth: 6, dash: [3, 2.2]))
                    Image(systemName: "testtube.2")
                        .healthGlyph(.promoArt)
                        .foregroundStyle(PulseTheme.textSecondary)
                }
                .frame(width: 92, height: 92)
                .accessibilityHidden(true)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
            .fill(LinearGradient(gradient: HealthPalette.labsPromo, startPoint: UnitPoint(x: 0.35, y: 0.6),
                                 endPoint: .topTrailing)))
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Opens the Lab Book"))
    }
}

/// Sixty rounded radial segments around "N / MARKERS ›", shared out by category in three strengths of the
/// neutral data blue, each segment brighter at its outer end (reviews/r44's ring, without status colours).
struct HealthLabRing: View {
    let categories: [HealthLabsSummary.Category]
    let total: Int

    private static let segments = 60

    var body: some View {
        ZStack {
            Canvas { context, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let outer = min(size.width, size.height) / 2
                let inner = outer - 16
                let shares = categories.map(\.markers)
                let sum = max(1, shares.reduce(0, +))
                var bounds: [Int] = []
                var running = 0
                for s in shares {
                    running += s
                    bounds.append(Int((Double(running) / Double(sum) * Double(Self.segments)).rounded()))
                }
                for i in 0..<Self.segments {
                    let band = bounds.firstIndex { i < $0 } ?? max(0, bounds.count - 1)
                    let strength = [1.0, 0.62, 0.38][min(band, 2)]
                    let angle = (Double(i) / Double(Self.segments)) * 2 * .pi - .pi / 2
                    var seg = Path()
                    let w: CGFloat = 4.2
                    seg.addRoundedRect(in: CGRect(x: inner, y: -w / 2, width: outer - inner, height: w),
                                       cornerSize: CGSize(width: 1.5, height: 1.5))
                    let t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: CGFloat(angle))
                    context.fill(seg.applying(t), with: .linearGradient(
                        Gradient(colors: [PulseTheme.recoveryBlue.opacity(0.15 * strength),
                                          PulseTheme.recoveryBlue.opacity(strength)]),
                        startPoint: CGPoint(x: c.x + inner * CGFloat(cos(angle)), y: c.y + inner * CGFloat(sin(angle))),
                        endPoint: CGPoint(x: c.x + outer * CGFloat(cos(angle)), y: c.y + outer * CGFloat(sin(angle)))))
                }
            }
            VStack(spacing: 2) {
                Text("\(total)")
                    .font(PulseType.font(.largeValue))
                    .foregroundStyle(PulseTheme.textPrimary)
                HStack(spacing: 4) {
                    Text(String(localized: "Markers"))
                        .pulseText(.label)
                        .foregroundStyle(PulseTheme.textSecondary)
                    PulseChevron(color: PulseTheme.textSecondary, size: 11)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: Health Monitor

/// HEALTH MONITOR ›: five equal columns split by 1 pt rules (RESP · SPO₂ · RHR · HRV · TEMP; SpO₂ only
/// with a real reading), each a line icon, a caps label and its 24 pt status square, over a well that
/// sums it up ("✓ 5/5 metrics within range", "! Heart rate variability low").
struct HealthMonitorCard: View {
    let vitals: [HealthVital]

    private var judged: [HealthVital] { vitals.filter { $0.status != .noData } }
    private var outside: [HealthVital] {
        vitals.filter { if case .outside = $0.status { return true } else { return false } }
    }

    var body: some View {
        PulseLink(.healthMonitor) {
            PulseCard {
                VStack(alignment: .leading, spacing: 18) {
                    PulseCardTitle(String(localized: "Health Monitor"), accessory: .trailingChevron)
                    HStack(spacing: 0) {
                        ForEach(Array(vitals.enumerated()), id: \.element.id) { index, vital in
                            column(vital)
                            if index < vitals.count - 1 {
                                Rectangle().fill(PulseTheme.divider).frame(width: 1, height: 74)
                            }
                        }
                    }
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                    VStack(alignment: .leading, spacing: 8) {
                        footer
                        ForEach(caveats, id: \.self) { line in
                            Text(line)
                                .pulseText(.secondary)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Health Monitor"))
        .accessibilityValue(([footerText] + caveats).joined(separator: ". "))
        .accessibilityHint(String(localized: "Opens Health Monitor"))
    }

    /// "HRV: unverified · over-reports R-R" (#1118), for each shown value the strap's capture makes doubtful.
    private var caveats: [String] {
        vitals.compactMap { v in v.caveat.map { "\(v.shortTitle): \($0)" } }
    }

    private func column(_ vital: HealthVital) -> some View {
        VStack(spacing: 10) {
            Image(systemName: vital.symbol)
                .healthGlyph(.columnIcon)
                .foregroundStyle(PulseTheme.textSecondary)
                .frame(height: 26)
            Text(vital.shortTitle)
                .pulseText(.label)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            badge(vital.status)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func badge(_ status: HealthVital.Status) -> some View {
        switch status {
        case .within: PulseStatusBadge(.check, tint: .teal)
        case .outside(let severe): PulseStatusBadge(.alert, tint: severe ? .red : .orange)
        case .noData: PulseStatusBadge(.pending, tint: .grey)
        }
    }

    private var footerText: String {
        if judged.isEmpty { return String(localized: "Calibrating your ranges") }
        if outside.isEmpty { return String(localized: "\(judged.count)/\(judged.count) metrics within range") }
        if outside.count == 1, let one = outside.first {
            return one.direction < 0 ? String(localized: "\(one.name) low") : String(localized: "\(one.name) high")
        }
        return String(localized: "\(outside.count)/\(judged.count) metrics out of range")
    }

    /// reviews/r44, r100: a 16 pt SOLID square (teal with a dark ✓, or orange / red with a dark "!") and
    /// 11 pt text (r100: "4/4 metrics within range" 117 pt wide, digits 7 pt tall) in a ≈32 pt black-20% well.
    private var footer: some View {
        HStack(spacing: 10) {
            HealthFooterMark(state: footerMark)
            Text(footerText)
                .pulseText(.chip)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.well, style: .circular)
            .fill(HealthPalette.monitorFooterWell))
    }

    private var footerMark: HealthFooterMark.State {
        if judged.isEmpty { return .pending }
        if outside.isEmpty { return .within }
        return .outside(severe: outside.contains { $0.status == .outside(severe: true) })
    }
}

/// The HEALTH MONITOR footer's 16 pt square: solid teal with a black ✓, solid orange or red with a black
/// "!", or a grey dash while calibrating (radius 3).
struct HealthFooterMark: View {
    enum State: Equatable {
        case within
        case outside(severe: Bool)
        case pending
    }

    let state: State

    var body: some View {
        let fill: Color
        let mark: String
        switch state {
        case .within: fill = PulseTheme.positive; mark = "checkmark"
        case .outside(let severe): fill = severe ? PulseTheme.recoveryLow : PulseTheme.negative; mark = "exclamationmark"
        case .pending: fill = PulseTheme.Tint.grey.fill; mark = "minus"
        }
        return RoundedRectangle(cornerRadius: 3, style: .circular)
            .fill(fill)
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: mark)
                    .healthGlyph(.footerMark)
                    .foregroundStyle(state == .pending ? PulseTheme.textPrimary : Color.black)
            )
            .accessibilityHidden(true)
    }
}

// MARK: Rhythm (opt-in)

/// RHYTHM › in the Heart Screener slot (§3.20 item 8 [Z]), only when switched on in Automations: a way into
/// last night's beat-to-beat pattern (the Rhythm screen draws it), plainly non-diagnostic.
struct HealthRhythmCard: View {
    var body: some View {
        PulseLink(.classic(.rhythm)) {
            PulseCard {
                VStack(alignment: .leading, spacing: 10) {
                    PulseCardTitle(String(localized: "Rhythm"), accessory: .trailingChevron)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "waveform.path")
                            .healthGlyph(.columnIcon)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .accessibilityHidden(true)
                        Text(String(localized: "See last night's beat-to-beat pattern. Experimental, and not an ECG: it cannot detect or rule out any heart condition."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityHint(String(localized: "Opens Rhythm"))
    }
}

// MARK: Menstrual cycle (opt-in)

/// The cycle card's slot: the one view on the tab that reads the cycle from `AppModel` (the temperature
/// engine's result), so the live heart rate it also publishes re-renders this and not the page. It builds
/// the card from Menstrual Cycle Insights' own funnel (`PulseSnapshotBuilder.cycleToday`: the logs first, the
/// engine only where they say nothing), again whenever a log, the engine, the mode or the contraception
/// changes. Like the classic card (`SkinTempCardsView`), it asks for a fresh engine read when there is no
/// phase yet, so the engine's estimate shows without waiting for AppModel's next 30-minute pass.
struct HealthCycleSlot: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var repo: Repository
    @Environment(PulseModel.self) private var model
    @AppStorage(PulseCycleLog.Mode.storageKey) private var modeRaw = PulseCycleLog.Mode.menstruating.rawValue
    @AppStorage(PulseCycleLog.Contraception.storageKey) private var contraceptionRaw = PulseCycleLog.Contraception.none.rawValue
    @State private var today: CycleTodaySnapshot?

    private struct LoadKey: Equatable {
        let health: String
        let logSeq: Int
        let mode: String
        let contraception: String
        let engine: CyclePhaseEngine.Result?
    }

    var body: some View {
        HealthCycleCard(today: today)
            .equatable()
            .task {
                if appModel.cyclePhase == nil { await appModel.refreshV5Signals() }
            }
            .task(id: LoadKey(health: model.healthKey, logSeq: repo.cycleTrackingSeq, mode: modeRaw,
                              contraception: contraceptionRaw, engine: appModel.cyclePhase)) {
                await load()
            }
    }

    private func load() async {
        let day = Repository.localDayKey(Date())
        let engine = appModel.cyclePhase
        let mode = PulseCycleLog.Mode(rawValue: modeRaw) ?? .menstruating
        let contraception = PulseCycleLog.Contraception(rawValue: contraceptionRaw) ?? .none
        if let s = await model.build(dayOffset: 0, { builder, request in
            await builder.cycleToday(request, today: day, engine: engine, mode: mode, contraception: contraception)
        }) {
            today = s
        }
    }
}

/// MENSTRUAL CYCLE INSIGHTS (§3.20 item 6), when cycle awareness is on: the phase over the cycle day ("Day
/// 21" in WHOOP's), a coral-to-lavender bar with today's white marker, and "+ LOG CYCLE". The label, the
/// day and the marker are the page's own header (`CycleTodaySnapshot`), so the card says what Menstrual
/// Cycle Insights says, and the bar shows only where the page draws phases (not under hormonal
/// contraception). The card opens that page; LOG CYCLE opens its own log sheet on today
/// (`PulseCycleCardLogSheet`), so a log made here is the same log, saved the same way.
struct HealthCycleCard: View, Equatable {
    let today: CycleTodaySnapshot?

    @State private var showsLog = false

    static func == (lhs: HealthCycleCard, rhs: HealthCycleCard) -> Bool {
        lhs.today == rhs.today
    }

    var body: some View {
        PulseCard {
            VStack(alignment: .leading, spacing: 16) {
                PulseLink(PulseRoute.cycleInsights.forExistingEntryPoint) {
                    VStack(alignment: .leading, spacing: 14) {
                        PulseCardTitle(String(localized: "Menstrual Cycle Insights"), accessory: .trailingChevron)
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let title = today?.header.title {
                                    PulseLabel(title)
                                }
                                Text(today?.headline ?? "--")
                                    .pulseText(.cardHeadline)
                                    .foregroundStyle(PulseTheme.textPrimary)
                            }
                            Spacer(minLength: 8)
                            if let place = today?.place {
                                bar(place.fraction)
                                    .frame(width: 150)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                Button {
                    showsLog = true
                } label: {
                    Label(String(localized: "Log cycle"), systemImage: "plus")
                }
                .buttonStyle(.pulseNested(fill: PulseTheme.Menstrual.logButton))
            }
        }
        .sheet(isPresented: $showsLog) {
            PulseCycleCardLogSheet()
        }
        #if DEBUG
        .onAppear { openDebugLogIfAsked() }
        #endif
    }

    #if DEBUG
    @MainActor private static var openedDebugLog = false

    /// `--pulse-health-log-cycle`: open LOG CYCLE's sheet once, for captures.
    private func openDebugLogIfAsked() {
        guard !Self.openedDebugLog, CommandLine.arguments.contains("--pulse-health-log-cycle") else { return }
        Self.openedDebugLog = true
        showsLog = true
    }
    #endif

    private func bar(_ position: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .circular)
                    .fill(LinearGradient(gradient: HealthPalette.cycleBar, startPoint: .leading, endPoint: .trailing))
                    .frame(height: 6)
                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .offset(x: min(max(0, geo.size.width * CGFloat(position) - 7), geo.size.width - 14))
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }
}

// MARK: Stress Monitor

/// STRESS MONITOR ›: "TODAY'S HIGH STRESS" over "4 hrs", "▼ vs. typical Tue" (teal when less than the
/// typical same weekday so far, orange when more), and the day so far as a value-coloured sparkline over
/// faint gridlines, ending at a dashed now-line with a white dot (reviews/r100, health-more-2026/03 frame 121).
/// ZENO scores stress by the hour, so the time prints in whole hours, not WHOOP's minute-precise h:mm.
/// Opens the Stress Monitor at today, whatever day Home shows (the Health tab is always now, §1.7).
struct HealthStressCardView: View {
    let card: HealthStressCard?
    let typicalHigh: HealthTypicalHigh?

    /// The typical weekday's HIGH minutes, only when they were built for the card's own day.
    private var typicalMinutes: Int? {
        guard let card, let typicalHigh, typicalHigh.dayKey == card.dayKey else { return nil }
        return typicalHigh.minutes
    }

    var body: some View {
        PulseLink(HealthStressMonitorRoute(startOffset: 0).route) {
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    PulseCardTitle(String(localized: "Stress Monitor"), accessory: .trailingChevron)
                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            PulseLabel(String(localized: "Today's high stress"))
                            let hours = card?.highMinutes.map { HealthFormat.stressHours(minutes: $0, long: true) }
                            PulseValueText(value: hours?.value ?? "--", unit: hours?.unit,
                                           style: .largeValue, unitStyle: .subtitle)
                            if let high = card?.highMinutes, let typical = typicalMinutes, let key = card?.dayKey {
                                PulseDeltaChip(text: String(localized: "vs. typical \(PulseFormat.dayLabel(key, template: "EEE"))"),
                                               trend: PulseTrend(delta: Double(high - typical), polarity: .lowerIsBetter))
                            } else if card?.highMinutes == nil {
                                Text(String(localized: "Fills in as your strap records heart rate today."))
                                    .pulseText(.secondary)
                                    .foregroundStyle(PulseTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if let card, card.points.contains(where: { $0.value != nil }) {
                            HealthStressSparkline(points: card.points, span: card.span, height: 74)
                                .frame(width: 150)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Stress Monitor"))
        .accessibilityValue(accessibility)
        .accessibilityHint(String(localized: "Opens Stress Monitor"))
    }

    private var accessibility: String {
        guard let high = card?.highMinutes else { return String(localized: "No stress readings yet today") }
        var text = String(localized: "\(HealthFormat.spokenHours(minutes: high)) in high stress today")
        if let typical = typicalMinutes {
            text += ", " + String(localized: "typical \(HealthFormat.spokenHours(minutes: typical))")
        }
        return text
    }
}

// MARK: ZENO extras

/// "More from ZENO" (§3.20 item 9 [Z]): the illness heads-up when the watch fires, and STEPS.
struct HealthExtras: View {
    let stepsToday: Double?
    let stepsRoute: TabRoute

    var body: some View {
        VStack(alignment: .leading, spacing: PulseTheme.Layout.gridGap) {
            HealthSectionHeader(title: String(localized: "More from ZENO"))
                .padding(.bottom, 4)
            HealthIllnessSlot()
            PulseLink(.tab(stepsRoute)) {
                PulseListRow(symbol: "figure.walk", title: String(localized: "Steps"),
                             subtitle: String(localized: "Today and your trend"),
                             trailing: .value(stepsToday.map { PulseFormat.grouped($0) } ?? "--"))
                    .padding(.horizontal, 16)
                    .frame(minHeight: PulseTheme.Row.listWithSubline)
                    .pulseCardBackground(.rowCard)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
        }
    }
}

/// The illness card's slot: the one view on the tab that reads the illness watch from `AppModel` (which
/// also publishes the live heart rate about once a second), shown only when the watch fires.
struct HealthIllnessSlot: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        if let illness = appModel.illnessSignal, illness.level == .raised || illness.level == .alreadyUnwell {
            HealthIllnessCard(result: illness)
                .equatable()
        }
    }
}

/// ILLNESS HEADS-UP: the illness watch's own words, the signals that are up, an orange-tinted rim. Opens
/// the classic Health screen, where the watch lives.
struct HealthIllnessCard: View, Equatable {
    let result: IllnessSignalEngine.Result

    private var message: String {
        let signals = ListFormatter.localizedString(byJoining: result.firedSignals)
        switch result.level {
        case .alreadyUnwell:
            return String(localized: "You logged feeling unwell. Take it easy today. On-device estimate, not a diagnosis.")
        default:
            return signals.isEmpty
                ? String(localized: "Your body looks strained. Consider taking it easy. On-device estimate, not a diagnosis.")
                : String(localized: "Your body looks strained. Signals up: \(signals). Consider taking it easy. On-device estimate, not a diagnosis.")
        }
    }

    var body: some View {
        PulseLink(.classic(.classicHealth)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: result.level == .alreadyUnwell ? "bed.double" : "exclamationmark.triangle")
                        .healthGlyph(.control)
                        .foregroundStyle(PulseTheme.negative)
                        .accessibilityHidden(true)
                    PulseCardTitle(String(localized: "Illness heads-up"), accessory: .trailingChevron)
                }
                Text(message)
                    .pulseText(.body)
                    .foregroundStyle(PulseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .fill(PulseTheme.Tint.orange.fill.opacity(0.6)))
            .overlay(RoundedRectangle(cornerRadius: PulseTheme.Radius.card, style: .circular)
                .strokeBorder(HealthPalette.illnessBorder, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityElement(children: .combine)
    }
}
#endif
