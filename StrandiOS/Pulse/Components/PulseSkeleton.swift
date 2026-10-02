#if os(iOS)
import SwiftUI

// MARK: - Loading skeletons (WHOOP_UI_SPEC §2.8, §3.1 "States"; DR §8)
//
// A screen that is still building shows white-10% blocks in the shape of what is coming, never a spinner:
//   - nothing at all for the first 200 ms (`PulseMotion.skeletonDelay`), so a fast load never flashes;
//   - once shown, the skeleton stays at least 400 ms (`PulseMotion.skeletonMinimum`), so it never blinks;
//   - no shimmer and no pulsing (no ambient motion); the content cross-fades in.
//
//     PulseLoadingGate(isLoading: snapshot == nil) {
//         if let snapshot { MyContent(snapshot) }
//     } skeleton: {
//         PulseSkeleton.dive
//     }

/// One skeleton block: white 10%, card radius, no animation.
struct PulseSkeletonBlock: View {
    var height: CGFloat
    var width: CGFloat?
    var radius: CGFloat = PulseTheme.Radius.card

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .circular)
            .fill(PulseTheme.skeleton)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
    }
}

/// Ready-made skeletons in the shape of the common screens.
enum PulseSkeleton {
    /// A deep dive: the 260 pt ring, then the callout and two cards.
    static var dive: some View {
        VStack(spacing: PulseTheme.Layout.stackGap) {
            Circle()
                .strokeBorder(PulseTheme.skeleton, lineWidth: PulseTheme.Dial.heroStroke)
                .frame(width: PulseTheme.Dial.heroDiameter, height: PulseTheme.Dial.heroDiameter)
                .frame(maxWidth: .infinity)
            PulseSkeletonBlock(height: 280)
            PulseSkeletonBlock(height: 160)
        }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Loading"))
    }

    /// A list of cards (Home below the dials, the Health tab).
    static func cards(_ heights: [CGFloat] = [96, 180, 150]) -> some View {
        VStack(spacing: PulseTheme.Layout.stackGap) {
            ForEach(Array(heights.enumerated()), id: \.offset) { _, h in
                PulseSkeletonBlock(height: h)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(String(localized: "Loading"))
    }
}

/// Shows `skeleton` while `isLoading`, but only after `PulseMotion.skeletonDelay`, and keeps it at least
/// `PulseMotion.skeletonMinimum` once shown; then the content cross-fades in.
struct PulseLoadingGate<Content: View, Skeleton: View>: View {
    let isLoading: Bool
    @ViewBuilder var content: () -> Content
    @ViewBuilder var skeleton: () -> Skeleton

    /// The skeleton is on screen (it may outlive `isLoading` to honour the minimum).
    @State private var showingSkeleton = false
    @State private var shownAt: ContinuousClock.Instant?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(isLoading: Bool, @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder skeleton: @escaping () -> Skeleton) {
        self.isLoading = isLoading
        self.content = content
        self.skeleton = skeleton
    }

    var body: some View {
        Group {
            if showingSkeleton {
                skeleton().transition(.opacity)
            } else if !isLoading {
                content().transition(.opacity)
            } else {
                // The first 200 ms: nothing, so a fast build never flashes a skeleton.
                Color.clear.frame(height: 1)
            }
        }
        .animation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion), value: showingSkeleton)
        .animation(PulseMotion.resolved(PulseMotion.crossFade, reduceMotion: reduceMotion), value: isLoading)
        .task(id: isLoading) {
            if isLoading {
                try? await Task.sleep(for: PulseMotion.skeletonDelay)
                guard !Task.isCancelled, isLoading else { return }
                shownAt = .now
                showingSkeleton = true
            } else if showingSkeleton {
                if let shownAt {
                    let remaining = PulseMotion.skeletonMinimum - (ContinuousClock.now - shownAt)
                    if remaining > .zero { try? await Task.sleep(for: remaining) }
                }
                guard !Task.isCancelled else { return }
                showingSkeleton = false
                shownAt = nil
            }
        }
    }
}

extension View {
    /// Replace this view with white-10% skeleton blocks of the same shape while `isLoading` (after
    /// 200 ms, for at least 400 ms). For content whose layout already exists while it loads.
    func pulseSkeleton(isLoading: Bool) -> some View {
        modifier(PulseSkeletonModifier(isLoading: isLoading))
    }
}

private struct PulseSkeletonModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        PulseLoadingGate(isLoading: isLoading) {
            content
        } skeleton: {
            content
                .redacted(reason: .placeholder)
                .foregroundStyle(PulseTheme.skeleton)
                .allowsHitTesting(false)
        }
    }
}
#endif
