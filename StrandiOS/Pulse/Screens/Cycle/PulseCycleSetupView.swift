#if os(iOS)
import SwiftUI

/// The page before Menstrual Cycle Insights is switched on: what it does, the privacy promise, and the
/// last-period question with an "I don't know" answer [Z] (WHOOP forces a date and reaches back only about
/// two months; ZENO accepts no date and lets the next logged period anchor the cycle). Once switched off
/// with logs kept, the same page offers to turn it back on.
struct PulseCycleSetupView: View {
    let hasLogs: Bool
    let onStart: (Date?) -> Void

    @State private var lastPeriod = Date()
    @State private var knowsDate = true

    private var earliest: Date {
        Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
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
                        Text(String(localized: "When did your last period start?"))
                            .pulseText(.subsectionTitle)
                            .foregroundStyle(PulseTheme.textPrimary)
                        if knowsDate {
                            DatePicker(String(localized: "Last period started"), selection: $lastPeriod,
                                       in: earliest...Date(), displayedComponents: .date)
                                .pulseText(.rowText)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .tint(PulseCyclePhase.menstrual.dot)
                        } else {
                            Text(String(localized: "That's fine. Your cycle day starts from the next period you log."))
                                .pulseText(.body)
                                .foregroundStyle(PulseTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        PulseButtonRow {
                            Button { onStart(knowsDate ? lastPeriod : nil) } label: {
                                Text(String(localized: "Get started"))
                            }
                            .buttonStyle(.pulseFilledWhite)
                            Button { knowsDate.toggle() } label: {
                                Text(knowsDate ? String(localized: "I don't know") : String(localized: "Pick a date"))
                            }
                            .buttonStyle(.pulseOutlineWhite)
                        }
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
    }
}
#endif
