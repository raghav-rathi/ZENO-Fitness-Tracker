#if os(iOS)
import SwiftUI

/// The Trend View's metric picker (WHOOP_UI_SPEC §3.12 item 2, [U]: WHOOP's sheet was never captured): a
/// sheet listing every metric grouped SLEEP · RECOVERY · STRAIN · STRESS · BODY under label-style section
/// headers, the current one ticked, and a quiet "No readings yet" under any metric without data.
/// Choosing one switches the Trend View in place.
struct PulseTrendMetricPicker: View {
    let selected: String
    let units: PulseTrendUnits
    let onSelect: (String) -> Void

    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var items: [PulseTrendPickerItem]?
    @ScaledMetric(relativeTo: .body) private var iconSize = PulseTheme.Trends.metricIcon
    @ScaledMetric(relativeTo: .body) private var tickSize = PulseTheme.Trends.pickerTick

    /// The rows before the availability scan lands: every metric, none marked.
    private var rows: [PulseTrendPickerItem] {
        items ?? PulseTrendMetric.curated.map {
            PulseTrendPickerItem(id: $0.key, title: $0.title, symbol: $0.symbol, pillar: $0.pillar, hasData: true)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(PulseTrendPillar.allCases) { pillar in
                            let group = rows.filter { $0.pillar == pillar }
                            if !group.isEmpty {
                                PulseListSectionHeader(pillar.title)
                                    .padding(.top, pillar == .sleep ? 8 : 28)
                                    .padding(.bottom, 12)
                                VStack(spacing: PulseTheme.Row.listGap) {
                                    ForEach(group) { item in row(item).id(item.id) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, PulseTheme.Layout.pageMargin)
                    .padding(.bottom, 32)
                }
                // Open on the current metric: from a Recovery or Strain page it sits below the SLEEP group.
                .onAppear { proxy.scrollTo(selected, anchor: .center) }
            }
            .background(PulseBackground())
            .pulseNavHeader(String(localized: "Choose a metric"), showsBack: false)
            .environment(\.pulseModalRoot, true)
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(PulseTheme.pageTop)
        .environment(\.colorScheme, .dark)
        .task(id: model.healthKey) {
            let units = self.units
            if let built = await model.build(dayOffset: 0, { builder, request in
                await builder.trendPicker(request, units: units)
            }) {
                items = built
            }
        }
    }

    private func row(_ item: PulseTrendPickerItem) -> some View {
        Button {
            onSelect(item.id)
            dismiss()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: item.symbol)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundStyle(PulseTheme.rowIcon)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .pulseText(.cardTitle)
                        .foregroundStyle(item.hasData ? PulseTheme.textPrimary : PulseTheme.textTertiary)
                        .lineLimit(2)
                    if !item.hasData {
                        Text(String(localized: "No readings yet"))
                            .pulseText(.rowSubline)
                            .foregroundStyle(PulseTheme.textTertiary)
                    }
                }
                Spacer(minLength: 8)
                if item.id == selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: tickSize, weight: .bold))
                        .foregroundStyle(PulseTheme.positive)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: PulseTheme.Row.list, alignment: .leading)
            .pulseCardBackground(.rowCard)
            .contentShape(Rectangle())
        }
        .buttonStyle(PulsePressStyle())
        .accessibilityLabel(item.title)
        .accessibilityValue(item.hasData ? "" : String(localized: "No readings yet"))
        .accessibilityAddTraits(item.id == selected ? .isSelected : [])
    }
}
#endif
