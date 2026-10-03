#if os(iOS)
import SwiftUI
import UIKit
import StrandAnalytics

/// Year in Review (WHOOP_UI_SPEC §3.39), presented as a full-screen story: "✕" at the top-left, the ZENO
/// wordmark with the year in its blue gradient, a near-black page with a glow rising from the foot in each
/// slide's colour, and the progress segments at the foot (completeness-critic/08–11,
/// profile-community-2026/45–53).
///
/// ZENO's version is the wearer's own year (§3.39 [Z]): the days tracked, the longest night, the highest
/// Recovery and the biggest day, the strongest pillar, the journal behaviours that moved Recovery, steps
/// with the Everest equivalence, a persona written from fixed rules, and a summary card to share. Every
/// WHOOP comparison with other members ([POP]) becomes a comparison with the wearer's own average. It
/// covers last year until 15 January and the year so far after that; under two weeks of data it says so
/// instead of telling a thin story. It never advances by itself (no running timer): tap the right of the
/// screen or swipe for the next slide, the left for the previous.
///
/// Owned by group "extras".
struct PulseYearInReviewView: View {
    /// Rebuilt: the route opens this story (it has no classic counterpart).
    static let isRebuilt = true

    /// The year to review; nil picks it from today (`PulseSnapshotBuilder.reviewYear`).
    var year: Int?

    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var snapshot: YearInReviewSnapshot?
    @State private var index = 0
    @State private var forward = true

    private typealias S = PulseExtrasTheme.Story

    init(year: Int? = nil) {
        self.year = year
    }

    private var reviewYear: Int { year ?? PulseSnapshotBuilder.reviewYear(now: Date()) }

    /// Whether Home's "Your 2026 in Review ›" card is in season (§3.39 [Z]: 1 December to 15 January). The
    /// Trends INSIGHTS row can open the story any time (a "so far" review outside the season).
    static func isInSeason(_ now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let c = calendar.dateComponents([.month, .day], from: now)
        return c.month == 12 || (c.month == 1 && (c.day ?? 1) <= 15)
    }

    /// The card's title: "Your 2025 in Review".
    static func seasonTitle(_ now: Date = Date()) -> String {
        String(localized: "Your \(String(PulseSnapshotBuilder.reviewYear(now: now))) in Review")
    }

    private var slides: [YearReviewSlide] {
        snapshot.map(YearReviewSlide.slides(for:)) ?? []
    }

    private var current: YearReviewSlide? {
        let all = slides
        return all.indices.contains(index) ? all[index] : all.last
    }

    var body: some View {
        ZStack {
            YearReviewBackground(glow: snapshot.flatMap { s in current.map { $0.glow(s) } } ?? S.glowIndigo)
                .pulseAnimation(PulseMotion.crossFade, value: index)

            VStack(spacing: 0) {
                header
                GeometryReader { geo in
                    ZStack {
                        if let snapshot, let current {
                            YearReviewSlideView(slide: current, snapshot: snapshot)
                                .id(index)
                                .transition(slideTransition)
                        } else {
                            loading
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { location in
                        // The left third steps back, the rest forward (the story convention).
                        go(to: location.x < geo.size.width / 3 ? index - 1 : index + 1)
                    }
                    .gesture(swipe)
                }
                progress
                    .padding(.top, 14)
                    .padding(.bottom, 22)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(false)
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .task(id: "\(model.seq)|\(reviewYear)") {
            let y = reviewYear
            if let s = await model.build(dayOffset: 0, { builder, request in await builder.yearInReview(request, year: y) }) {
                snapshot = s
                index = min(index, max(0, YearReviewSlide.slides(for: s).count - 1))
                #if DEBUG
                if let i = CommandLine.arguments.firstIndex(of: "--pulse-yir-slide"), i + 1 < CommandLine.arguments.count,
                   let n = Int(CommandLine.arguments[i + 1]) {
                    index = min(max(0, n), YearReviewSlide.slides(for: s).count - 1)
                }
                #endif
            }
        }
    }

    // MARK: Chrome

    /// "✕" at the left; the wordmark and the year centred.
    private var header: some View {
        ZStack {
            // The summary card carries its own lock-up.
            if current != .summary { YearReviewLockup(year: reviewYear) }
            HStack {
                PulseCloseButton { dismiss() }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .frame(height: PulseTheme.Header.navBar)
        .padding(.top, PulseTheme.Header.navBarTop)
    }

    /// Short white segments for the slides seen, a long one for this slide, short grey ones ahead.
    private var progress: some View {
        let count = max(1, slides.count)
        return HStack(spacing: S.segmentGap) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i <= index ? S.segmentDone : S.segmentUpcoming)
                    .frame(width: i == index ? S.segmentCurrentWidth : S.segmentWidth, height: S.segmentHeight)
            }
        }
        .pulseAnimation(PulseMotion.crossFade, value: index)
        .frame(height: 20)
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Slide \(index + 1) of \(count)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: go(to: index + 1)
            case .decrement: go(to: index - 1)
            @unknown default: break
            }
        }
    }

    private var loading: some View {
        VStack(spacing: PulseTheme.Layout.stackGap) {
            PulseSkeletonBlock(height: 44, width: 200)
            PulseSkeletonBlock(height: 258, width: S.cardSize.width, radius: S.cardTopRadius)
            PulseSkeletonBlock(height: 24, width: 240)
        }
        .pulseSkeleton(isLoading: true)
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Loading"))
    }

    // MARK: Moving between slides

    private var slideTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                           removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity))
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                if value.translation.width < -40 { go(to: index + 1) }
                if value.translation.width > 40 { go(to: index - 1) }
            }
    }

    private func go(to next: Int) {
        let count = slides.count
        guard count > 0, next >= 0, next < count, next != index else { return }
        forward = next > index
        withAnimation(PulseMotion.resolved(.easeInOut(duration: 0.3), reduceMotion: reduceMotion)) {
            index = next
        }
    }
}

// MARK: - Background and lock-up

/// The story's page: #07080D, with `glow` rising from the foot, brightest at the centre.
struct YearReviewBackground: View {
    let glow: Color

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        ZStack {
            S.page
            LinearGradient(stops: [
                .init(color: glow.opacity(0), location: S.glowStart),
                .init(color: glow.opacity(0.55), location: 0.85),
                .init(color: glow.opacity(0.8), location: 1)
            ], startPoint: .top, endPoint: .bottom)
            GeometryReader { geo in
                RadialGradient(colors: [glow.opacity(0.55), glow.opacity(0)],
                               center: UnitPoint(x: 0.5, y: 1.02),
                               startRadius: 0, endRadius: geo.size.height * 0.42)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The ZENO wordmark and the year in its italic blue gradient ("ZENO 2026"; WHOOP's lock-up, ZENO's mark).
struct YearReviewLockup: View {
    let year: Int
    var wordmarkWidth: CGFloat = PulseExtrasTheme.Story.wordmark.width

    private typealias S = PulseExtrasTheme.Story

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            PulseZenoWordmark(width: wordmarkWidth, height: wordmarkWidth * S.wordmark.height / S.wordmark.width)
            Text(verbatim: String(year))
                .font(.system(size: S.yearSize, weight: .bold).italic())
                .foregroundStyle(LinearGradient(gradient: S.year, startPoint: .leading, endPoint: .trailing))
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "ZENO \(String(year)) Year in Review"))
        .accessibilityAddTraits(.isHeader)
    }
}
#endif
