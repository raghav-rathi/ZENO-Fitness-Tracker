#if os(iOS)
import SwiftUI

// MARK: - Composer (WHOOP_UI_SPEC §3.16 "Composer"; profile-community-2026/66, 29, reviews/r123)
//
// A 44 pt "+" square (a new conversation) and the field: 48 pt, radius 14, the 1.5 pt AI input gradient
// border, "Ask ZENO anything", and inside it at the right the mic, or ↑ once there is something to send.
// Dictation reuses the classic Coach's on-device `CoachVoiceInput` (no audio leaves the iPhone; permission is
// asked on the first tap, never on open). While it listens, the field turns into WHOOP's "✕ ······ ✓" bar:
// ✕ drops what was heard, ✓ keeps it in the draft.

struct PulseCoachComposer: View {
    @Binding var draft: String
    let isSending: Bool
    let onSend: () -> Void
    let onNewChat: () -> Void

    @StateObject private var voice = CoachVoiceInput()
    @State private var listening = false
    @State private var heard = ""
    @State private var voiceStatus: String?
    @FocusState private var focused: Bool

    private var trimmed: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 12) {
                if !listening {
                    Button(action: onNewChat) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(PulseTheme.textPrimary)
                            .frame(width: 48, height: 48)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(PulseTheme.nested))
                    }
                    .buttonStyle(PulsePressStyle())
                    .accessibilityLabel(String(localized: "New conversation"))
                }
                if listening { listeningBar } else { field }
            }
            if let voiceStatus {
                Text(voiceStatus)
                    .pulseText(.legend)
                    .foregroundStyle(PulseTheme.textTertiary)
                    .padding(.leading, 60)
            }
        }
        .onDisappear {
            if listening { voice.stopTranscribing { _ in } }
        }
    }

    private var field: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return HStack(alignment: .bottom, spacing: 8) {
            TextField(String(localized: "Ask ZENO anything"), text: $draft, axis: .vertical)
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .lineLimit(1...5)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit(send)
                .padding(.vertical, 13)
                .accessibilityLabel(String(localized: "Question"))
            if trimmed.isEmpty {
                Button(action: startListening) {
                    Image(systemName: "mic")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(PulseTheme.Coach.composerMic)
                        .frame(width: 36, height: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .disabled(isSending)
                .accessibilityLabel(String(localized: "Ask out loud"))
                .accessibilityHint(String(localized: "Transcribes your question on this iPhone"))
            } else {
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(isSending ? PulseTheme.textDisabled : Color.white))
                        .frame(width: 36, height: 46)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PulsePressStyle())
                .disabled(isSending)
                .accessibilityLabel(String(localized: "Send"))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(minHeight: 48)
        .background(shape.fill(PulseTheme.Coach.composerFill))
        .overlay(shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.aiInputBorder,
                                                   startPoint: .leading, endPoint: .trailing),
                                    lineWidth: 1.5).opacity(focused || !trimmed.isEmpty ? 1 : 0.55))
        .contentShape(shape)
        .onTapGesture { focused = true }
    }

    /// "✕ ········· ✓" while dictating, with what has been heard so far.
    private var listeningBar: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return HStack(spacing: 10) {
            Button(action: cancelListening) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PulseTheme.textPrimary)
                    .frame(width: 44, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Stop and discard"))
            Group {
                if heard.isEmpty {
                    PulseCoachDottedRule()
                        .frame(height: 2)
                        .accessibilityLabel(String(localized: "Listening"))
                } else {
                    Text(heard)
                        .pulseText(.subtitle)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .lineLimit(2)
                        .truncationMode(.head)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: finishListening) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PulseTheme.Gradients.aiArrow)
                    .frame(width: 44, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Use what I said"))
        }
        .frame(minHeight: 52)
        .background(shape.fill(Color.black))
        .overlay(shape.strokeBorder(LinearGradient(gradient: PulseTheme.Gradients.aiInputBorder,
                                                   startPoint: .leading, endPoint: .trailing), lineWidth: 1.5))
    }

    // MARK: Actions

    private func send() {
        guard !trimmed.isEmpty, !isSending else { return }
        focused = false
        onSend()
    }

    private func startListening() {
        voiceStatus = nil
        switch voice.authorization {
        case .notDetermined:
            voice.requestAuthorization { state in
                if state == .authorized { begin() } else { voiceStatus = String(localized: "Allow speech recognition and the microphone in Settings to ask out loud.") }
            }
        case .authorized:
            begin()
        case .denied:
            voiceStatus = String(localized: "Allow speech recognition and the microphone in Settings to ask out loud.")
        case .unavailable:
            voiceStatus = String(localized: "Voice input isn't available on this iPhone.")
        }
    }

    private func begin() {
        guard voice.canUseVoice else {
            voiceStatus = voice.statusMessage ?? String(localized: "On-device speech isn't available for your language.")
            return
        }
        heard = ""
        focused = false
        listening = true
        voice.startTranscribing { partial in heard = partial }
    }

    private func finishListening() {
        voice.stopTranscribing { final in
            let text = final.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { draft = draft.isEmpty ? text : draft + " " + text }
            listening = false
            heard = ""
        }
    }

    private func cancelListening() {
        voice.stopTranscribing { _ in }
        listening = false
        heard = ""
    }
}

/// The dotted line of the listening bar.
struct PulseCoachDottedRule: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(PulseTheme.textTertiary, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.1, 5]))
        }
    }
}

// MARK: - Suggestion chips (§3.16: white capsules, h 36, black 15 pt text, scrolling sideways)

struct PulseCoachChips: View {
    let prompts: [String]
    let disabled: Bool
    let onPick: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(prompts, id: \.self) { prompt in
                    Button { onPick(prompt) } label: {
                        Text(prompt)
                            .pulseText(.subtitle)
                            .foregroundStyle(Color.black)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 38)
                            .background(Capsule(style: .continuous).fill(Color.white))
                    }
                    .buttonStyle(PulsePressStyle())
                    .disabled(disabled)
                    .accessibilityLabel(String(localized: "Suggested question: \(prompt)"))
                }
            }
            .padding(.horizontal, PulseTheme.Layout.pageMargin)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }
}
#endif
