#if os(iOS)
import SwiftUI
import MarkdownUI

// MARK: - Coach messages (WHOOP_UI_SPEC §3.16 "Messages"; reviews/r123, profile-community-2026/66, 74)
//
// Assistant replies are plain text with no bubble, 17 pt at white ≈88%, bold for numbers and names, bullets
// allowed, with a row of small actions under each. The wearer's turns are right-aligned bubbles in the
// sampled #343850. A grey line with a light-blue ✧ above a bubble says what went along with it (the page it
// was asked from, the memories it used), as WHOOP's action receipts do.

extension Theme {
    /// Coach replies on the sheet, at `size` (the 17 pt style, scaled with Dynamic Type).
    static func pulseCoach(size: CGFloat) -> Theme {
        Theme()
            .text {
                ForegroundColor(PulseTheme.textPrimary.opacity(0.88))
                FontSize(size)
            }
            .strong {
                FontWeight(.semibold)
                ForegroundColor(PulseTheme.textPrimary)
            }
            .emphasis {
                FontStyle(.italic)
            }
            .link {
                ForegroundColor(PulseTheme.recoveryBlue)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.88))
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: 14, bottom: 8)
                    .markdownTextStyle { FontWeight(.semibold); FontSize(size + 1) }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: 14, bottom: 8)
                    .markdownTextStyle { FontWeight(.semibold); FontSize(size + 1) }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: 12, bottom: 6)
                    .markdownTextStyle { FontWeight(.semibold); FontSize(size) }
            }
            .paragraph { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.3))
                    .markdownMargin(top: 0, bottom: 14)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.35))
            }
            .table { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownTableBorderStyle(.init(color: PulseTheme.divider))
                    .markdownMargin(top: 4, bottom: 12)
            }
            .tableCell { configuration in
                configuration.label
                    .markdownTextStyle {
                        if configuration.row == 0 { FontWeight(.semibold) }
                        FontSize(.em(0.88))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
            }
    }
}

/// One assistant reply, with copy, share and save-to-journal under it once it has finished.
struct PulseCoachAssistantMessage: View {
    let text: String
    let isStreaming: Bool
    var onSaveToJournal: (() -> Void)?

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = PulseTextStyle.trendInsight.spec.size
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Markdown(text)
                .markdownTheme(.pulseCoach(size: size))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if !isStreaming {
                HStack(spacing: 22) {
                    action(copied ? "checkmark" : "doc.on.clipboard", label: String(localized: "Copy")) {
                        UIPasteboard.general.string = text
                        copied = true
                    }
                    ShareLink(item: text) {
                        icon("square.and.arrow.up")
                    }
                    .accessibilityLabel(String(localized: "Share"))
                    if let onSaveToJournal {
                        action("square.and.pencil", label: String(localized: "Save to Journal"), perform: onSaveToJournal)
                    }
                }
                .sensoryFeedback(.success, trigger: copied)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func action(_ symbol: String, label: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) { icon(symbol) }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(label)
    }

    private func icon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(PulseTheme.textTertiary)
            .frame(minWidth: 30, minHeight: PulseTheme.Layout.minTapTarget)
            .contentShape(Rectangle())
    }
}

/// The wearer's turn: the question in a right-aligned bubble, the receipt above it.
struct PulseCoachUserMessage: View {
    let text: String
    var onRemember: (() -> Void)?

    var body: some View {
        let parsed = PulseCoachEnvelope.parse(text)
        VStack(alignment: .trailing, spacing: 8) {
            if let receipt = PulseCoachEnvelope.receipt(parsed) {
                PulseCoachReceipt(text: receipt)
            }
            HStack {
                Spacer(minLength: 48)
                Text(parsed.question)
                    .pulseText(.trendInsight)
                    .foregroundStyle(PulseTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(PulseTheme.Gradients.coachUserBubble))
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = parsed.question
                        } label: {
                            Label(String(localized: "Copy"), systemImage: "doc.on.doc")
                        }
                        if let onRemember {
                            Button(action: onRemember) {
                                Label(String(localized: "Add to My Memory"), systemImage: "lightbulb")
                            }
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "You said: \(parsed.question)"))
    }
}

/// "✧ Shared your Sleep summary": a grey line with a light-blue sparkle.
struct PulseCoachReceipt: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PulseTheme.Gradients.aiArrow)
                .accessibilityHidden(true)
            Text(text)
                .pulseText(.rowSubline)
                .foregroundStyle(PulseTheme.textSecondary)
        }
    }
}

/// While a reply is on its way and nothing has streamed yet.
struct PulseCoachThinking: View {
    var body: some View {
        HStack(spacing: 10) {
            PulseCoachAvatar(size: 22)
            Text(String(localized: "Thinking…"))
                .pulseText(.rowText)
                .foregroundStyle(PulseTheme.textTertiary)
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
