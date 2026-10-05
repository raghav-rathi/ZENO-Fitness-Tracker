import SwiftUI
import StrandDesign

/// "What's New" — a proper in-app changelog, shown automatically after an update and reachable any
/// time from Settings. It also restates, up top, what NOOP is and what to expect, so people who never
/// open GitHub still understand the experimental footing and the WHOOP 5/MG status.
///
/// Under the iPhone's Pulse interface the app is ZENO (`ScoreVocabulary`, spec §0.3): the sheet leads
/// with what ZENO adds (`AppChangelog.Zeno`), then the expectations, then NOOP's release history under
/// an "Earlier, as NOOP" heading, its text exactly as NOOP published it. The Mac and the classic iPhone
/// shell show the classic sheet, unchanged.
struct WhatsNewView: View {
    let onClose: () -> Void

    /// The interface's vocabulary, read at render.
    private var vocabulary: ScoreVocabulary { .current }

    var body: some View {
        VStack(spacing: 0) {
            header
                // A scenic Charge-tinted hero behind the title region — the same premium backdrop
                // the Today rings float over, so the changelog opens on-brand.
                .background {
                    ScenicHeroBackground(domain: .charge, starCount: 28, fadesToBase: true)
                }
            Divider().overlay(StrandPalette.hairline)
            ScrollView {
                // PERF: the changelog grows with every release, so this is an ever-lengthening column.
                // LazyVStack (byte-identical layout to VStack inside a ScrollView — same leading
                // alignment + sectionGap spacing) builds the off-screen release cards on demand instead
                // of constructing the entire history up-front each time the sheet opens.
                LazyVStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    // Pulse leads with ZENO's own entry, so it is the first thing the sheet shows.
                    if vocabulary == .pulse { zenoCard }
                    expectationsCard
                    if vocabulary == .pulse { earlierHeading }
                    ForEach(Array(AppChangelog.releases.enumerated()), id: \.element.id) { index, release in
                        // The newest release is the headline — give it the brand-green wash; the
                        // rest stay frosted-neutral so the latest stands out at a glance. Under Pulse the
                        // ZENO entry is the headline and NOOP's history stays neutral.
                        releaseCard(release, isLatest: index == 0 && vocabulary == .classic)
                    }
                }
                .padding(20)
            }
            #if os(iOS)
            // #697/#horizontal-swipe parity: every other screen (ScreenScaffold, Liquid Today) already
            // stops a vertical scroll from drifting/bouncing the screen left-right. This sheet runs its
            // own ScrollView and had never gotten the fix.
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            #endif
            Divider().overlay(StrandPalette.hairline)
            footer
        }
        // A fixed 560×640 is right for the macOS sheet window, but on iPhone it's wider than the
        // screen, so the content (and the "Got it" button) ran off the right edge (#185). iOS fills
        // the presented sheet instead.
        #if os(macOS)
        .frame(width: 560, height: 640)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // A long changelog scroll → open full-height, with a grabber for swipe-to-dismiss.
        .noopSheetPresentation(largeFirst: true)
        #endif
        .background(StrandPalette.surfaceBase)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WHAT'S NEW").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textTertiary)
                Text(vocabulary.pick(classic: LocalizedStringKey("NOOP \(AppChangelog.currentVersion)"),
                                     pulse: LocalizedStringKey("ZENO \(AppChangelog.currentVersion)")))
                    .font(StrandFont.rounded(26, weight: .bold))
                    .foregroundStyle(StrandPalette.textPrimary)
                Text("Release notes").font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(20)
    }

    private var expectationsCard: some View {
        NoopCard(tint: StrandPalette.accent) {
            VStack(alignment: .leading, spacing: 14) {
                Text("WHAT TO EXPECT").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textSecondary)
                ForEach(AppChangelog.expectations) { e in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: e.icon)
                            .foregroundStyle(StrandPalette.accent)
                            .frame(width: 22)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(e.title).font(StrandFont.headline)
                                .foregroundStyle(StrandPalette.textPrimary)
                            Text(e.body).font(StrandFont.subhead)
                                .foregroundStyle(StrandPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// ZENO's own entry (Pulse only): what ZENO adds to the NOOP it is built from, as the headline card.
    private var zenoCard: some View {
        NoopCard(tint: StrandPalette.accent) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    SourceBadge("ZENO")
                    Text(AppChangelog.Zeno.title).font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text(AppChangelog.Zeno.date).font(StrandFont.caption)
                        .foregroundStyle(StrandPalette.textTertiary)
                }
                ForEach(AppChangelog.Zeno.highlights) { highlight in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(StrandPalette.accent).frame(width: 5, height: 5)
                            .padding(.top, 7)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(highlight.lead).font(StrandFont.subhead.weight(.semibold))
                                .foregroundStyle(StrandPalette.textPrimary)
                            Text(highlight.body).font(StrandFont.subhead)
                                .foregroundStyle(StrandPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The heading over NOOP's history under Pulse: its release notes stay NOOP's, credited as such.
    private var earlierHeading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EARLIER, AS NOOP").font(StrandFont.overline)
                .tracking(StrandFont.overlineTracking)
                .foregroundStyle(StrandPalette.textTertiary)
            Text("ZENO is built on NOOP, the independent, on-device companion app for WHOOP straps. Its release notes follow as NOOP published them.")
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func releaseCard(_ release: AppChangelog.Release, isLatest: Bool = false) -> some View {
        NoopCard(tint: isLatest ? StrandPalette.accent : nil) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    SourceBadge("v\(release.version)")
                    Text(release.title).font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Spacer()
                    Text(release.date).font(StrandFont.caption)
                        .foregroundStyle(StrandPalette.textTertiary)
                }
                ForEach(Array(release.items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(StrandPalette.accent).frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item).font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Text("Got it").frame(minWidth: 120).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(StrandPalette.accent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}
