#if os(iOS)
import SwiftUI

/// The page before Menstrual Cycle Insights is switched on: what it does, the privacy promise, and the
/// last-period question with an "I don't know" answer [Z] (WHOOP forces a date and reaches back only about
/// two months; ZENO accepts no date and lets the next logged period anchor the cycle). Once switched off
/// with logs kept, the same page offers to turn it back on.
///
/// Nothing is pre-filled: the date row reads "Choose a date" until the wearer confirms one in the wheel, and
/// GET STARTED waits for a date or "I don't know", so tapping straight through never logs a period start
/// the wearer did not enter.
struct PulseCycleSetupView: View {
    let hasLogs: Bool
    let onStart: (Date?) -> Void

    private enum Answer: Equatable {
        case date(Date)
        case unknown
    }

    @State private var answer: Answer?
    @State private var picking = false
    @State private var wheelDay = Calendar.current.startOfDay(for: Date())

    /// The last 90 days, newest first.
    private var days: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<90).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(PulseCyclePhase.allCases, id: \.self) { phase in
                    Capsule().fill(phase.dot).frame(width: 26, height: 10)
                }
            }
            .padding(.top, 28)
            .accessibilityHidden(true)

            Text(String(localized: "See how your cycle shapes your Recovery, Strain and Sleep."))
                .pulseText(.pageTitle)
                .foregroundStyle(PulseTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)
                .accessibilityAddTraits(.isHeader)

            Text(String(localized: "Log your periods and symptoms to see your cycle day and phase, a window for your next period, and how your own Recovery, HRV and resting heart rate move across your cycle. Everything is worked out on this iPhone."))
                .pulseText(.subtitle)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            PulseCard {
                VStack(alignment: .leading, spacing: 16) {
                    if hasLogs {
                        Text(String(localized: "Your logged periods and symptoms are still on this iPhone. Turn the insights back on to see them."))
                            .pulseText(.body)
                            .foregroundStyle(PulseTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button { onStart(nil) } label: { Text(String(localized: "Turn on")) }
                            .buttonStyle(.pulseFilledWhite)
                    } else {
                        question
                    }
                }
            }
            .padding(.top, 28)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)
                Text(String(localized: "Nothing about your cycle leaves this iPhone unless you export a backup yourself. You can delete it all in settings at any time."))
                    .pulseText(.rowSubline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(PulseTheme.textTertiary)
            .padding(.top, 16)
            .accessibilityElement(children: .combine)

            PulseCycleDisclaimerCard()
                .padding(.top, PulseTheme.Layout.healthStackGap)
        }
        .sheet(isPresented: $picking) {
            PulseWheelPickerSheet(title: String(localized: "Last period started"), options: days,
                                  selection: $wheelDay, label: dayLabel,
                                  onConfirm: {
                                      answer = .date(wheelDay)
                                      picking = false
                                  },
                                  onCancel: { picking = false })
                .presentationDetents([.height(380)])
        }
    }

    @ViewBuilder
    private var question: some View {
        Text(String(localized: "When did your last period start?"))
            .pulseText(.subsectionTitle)
            .foregroundStyle(PulseTheme.textPrimary)
        if answer == .unknown {
            Text(String(localized: "That's fine. Your cycle day starts from the next period you log."))
                .pulseText(.body)
                .foregroundStyle(PulseTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Button {
                if case .date(let day) = answer { wheelDay = day }
                picking = true
            } label: {
                HStack(spacing: 12) {
                    Text(String(localized: "Last period started"))
                        .pulseText(.rowText)
                        .foregroundStyle(PulseTheme.textSecondary)
                    Spacer(minLength: 8)
                    Text(chosenText)
                        .pulseText(.rowText)
                        .foregroundStyle(answer == nil ? PulseCyclePhase.menstrual.dot : PulseTheme.textPrimary)
                    PulseChevron(color: PulseTheme.textTertiary, size: 13)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .pulseCardBackground(.nested, radius: PulseTheme.Radius.control)
                .contentShape(Rectangle())
            }
            .buttonStyle(PulsePressStyle())
            .accessibilityLabel(String(localized: "Last period started"))
            .accessibilityValue(chosenText)
            .accessibilityHint(String(localized: "Opens a list of the last 90 days"))
        }
        PulseButtonRow {
            Button {
                switch answer {
                case .date(let day): onStart(day)
                case .unknown: onStart(nil)
                case nil: break
                }
            } label: {
                Text(String(localized: "Get started"))
            }
            .buttonStyle(.pulseFilledWhite)
            .disabled(answer == nil)
            // The shared style draws no disabled state; dim it until there is an answer.
            .opacity(answer == nil ? 0.35 : 1)
            Button { answer = answer == .unknown ? nil : .unknown } label: {
                Text(answer == .unknown ? String(localized: "Pick a date") : String(localized: "I don't know"))
            }
            .buttonStyle(.pulseOutlineWhite)
        }
    }

    private var chosenText: String {
        if case .date(let day) = answer { return dayLabel(day) }
        return String(localized: "Choose a date")
    }

    private func dayLabel(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return String(localized: "Today") }
        if calendar.isDateInYesterday(day) { return String(localized: "Yesterday") }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}
#endif
