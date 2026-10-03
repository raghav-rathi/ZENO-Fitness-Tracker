#if os(iOS)
import SwiftUI
import UIKit
import PhotosUI
import StrandAnalytics

/// ZENO Live (WHOOP_UI_SPEC §3.10): today's numbers laid over a photo, to share.
///
/// WHOOP Live overlays live heart rate, Day Strain, Recovery or Sleep on a photo or video; the spec has no
/// capture of it ([U] visuals), so this follows its [Z] outline: pick a photo, choose an overlay (the three
/// dials on a card, Recovery, the Strain ring, or heart rate), drag it into place, and share the result.
/// Everything stays on the phone: the photo comes through the system picker (which needs no library
/// permission), the picture is composed here, and it leaves only through the share sheet. Its numbers are
/// Home's (the same resolvers), and the heart rate is shown only when a reading is under 15 minutes old.
/// Taking a photo with the camera needs a camera permission the app does not declare, so only the library
/// is offered for now.
///
/// Owned by group "extras". Opened by `PulseZenoLiveRoute` (full screen).
struct PulseZenoLiveView: View {
    @Environment(PulseModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var snapshot: ZenoLiveSnapshot?
    @State private var pick: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var template: ZenoLiveTemplate = .dials
    /// Where the overlay's centre sits, as a fraction of the picture.
    @State private var position = CGPoint(x: 0.5, y: 0.8)
    @State private var dragStart: CGPoint?
    @State private var exporting = false

    var body: some View {
        PulseScreenScaffold(title: String(localized: "ZENO Live"), spacing: 16) {
            GeometryReader { geo in
                let canvas = canvasSize(fitting: geo.size)
                composite(canvas: canvas, editable: true)
                    .frame(width: canvas.width, height: canvas.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: canvasHeight)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ZenoLiveTemplate.allCases) { t in
                        PulseFilterChip(title: t.title, isSelected: template == t) { template = t }
                    }
                }
            }
            .scrollClipDisabled()

            PulseButtonRow {
                PhotosPicker(selection: $pick, matching: .images, photoLibrary: .shared()) {
                    Label(photo == nil ? String(localized: "Choose photo") : String(localized: "Change photo"),
                          systemImage: "photo")
                }
                .buttonStyle(.pulseOutlineWhite)
                Button { share() } label: {
                    Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.pulseFilledWhite)
                .disabled(photo == nil || exporting)
                .opacity(photo == nil ? 0.4 : 1)
            }
            Text(String(localized: "Drag the numbers where you want them. The picture is made on this iPhone and leaves it only if you share it."))
                .pulseText(.legend)
                .foregroundStyle(PulseTheme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .task(id: model.seq) {
            if let s = await model.build(dayOffset: 0, { builder, request in await builder.zenoLive(request) }) {
                snapshot = s
            }
        }
        .onChange(of: pick) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    photo = image
                }
            }
        }
        #if DEBUG
        .onAppear {
            if photo == nil, CommandLine.arguments.contains("--pulse-zeno-live-sample") {
                photo = ZenoLiveSample.image()
            }
        }
        #endif
    }

    /// The picture area's height: the screen less the chips, buttons and caption under it.
    private var canvasHeight: CGFloat { 470 }

    /// The photo's shape fitted into `space`, or 4:5 with no photo yet.
    private func canvasSize(fitting space: CGSize) -> CGSize {
        let aspect: CGFloat = photo.map { max(0.4, min(2.5, $0.size.width / max(1, $0.size.height))) } ?? 0.8
        var w = space.width
        var h = w / aspect
        if h > space.height {
            h = space.height
            w = h * aspect
        }
        return CGSize(width: w, height: h)
    }

    @ViewBuilder
    private func composite(canvas: CGSize, editable: Bool) -> some View {
        ZenoLiveComposite(photo: photo, template: template, snapshot: snapshot, position: position, canvas: canvas,
                          editable: editable)
            .gesture(drag(canvas: canvas), including: editable ? .all : .none)
            .accessibilityElement(children: .contain)
            .accessibilityAction(named: String(localized: "Move up")) { nudge(dy: -0.1) }
            .accessibilityAction(named: String(localized: "Move down")) { nudge(dy: 0.1) }
            .accessibilityAction(named: String(localized: "Move left")) { nudge(dx: -0.1) }
            .accessibilityAction(named: String(localized: "Move right")) { nudge(dx: 0.1) }
    }

    private func drag(canvas: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let start = dragStart ?? position
                if dragStart == nil { dragStart = position }
                position = clamp(CGPoint(x: start.x + value.translation.width / max(1, canvas.width),
                                         y: start.y + value.translation.height / max(1, canvas.height)))
            }
            .onEnded { _ in dragStart = nil }
    }

    private func nudge(dx: CGFloat = 0, dy: CGFloat = 0) {
        position = clamp(CGPoint(x: position.x + dx, y: position.y + dy))
    }

    private func clamp(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, 0.12), 0.88), y: min(max(p.y, 0.1), 0.9))
    }

    /// Compose the picture at the photo's own resolution and offer it through the share sheet.
    @MainActor
    private func share() {
        guard let photo else { return }
        exporting = true
        defer { exporting = false }
        let canvas = canvasSize(fitting: CGSize(width: 360, height: 10_000))
        let pixelWidth = photo.size.width * photo.scale
        let renderer = ImageRenderer(content: ZenoLiveComposite(photo: photo, template: template, snapshot: snapshot,
                                                                position: position, canvas: canvas, editable: false)
            .frame(width: canvas.width, height: canvas.height)
            .environment(\.colorScheme, .dark))
        renderer.scale = min(max(1, pixelWidth / canvas.width), 6)
        guard let data = renderer.uiImage?.jpegData(compressionQuality: 0.9) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ZENO-Live.jpg")
        do { try data.write(to: url, options: .atomic) } catch { return }
        PulseExtrasShareSheet.present(url)
    }
}

/// The overlays to choose from.
enum ZenoLiveTemplate: String, CaseIterable, Identifiable {
    case dials, recovery, strain, heartRate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dials: return String(localized: "All three")
        case .recovery: return PulseScore.recovery.displayName
        case .strain: return PulseScore.strain.displayName
        case .heartRate: return String(localized: "Heart rate")
        }
    }
}

/// The photo (or, before one is chosen, an empty well) with the overlay at `position`.
struct ZenoLiveComposite: View {
    let photo: UIImage?
    let template: ZenoLiveTemplate
    let snapshot: ZenoLiveSnapshot?
    let position: CGPoint
    let canvas: CGSize
    let editable: Bool

    /// Overlays are drawn for a 360 pt wide picture and scaled with it, so the exported photo matches.
    private var scale: CGFloat { canvas.width / 360 }

    var body: some View {
        ZStack {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: canvas.width, height: canvas.height)
                    .clipped()
                    .accessibilityHidden(true)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(PulseTheme.card)
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(PulseTheme.textTertiary)
                    Text(String(localized: "Choose a photo to put today's numbers on."))
                        .pulseText(.body)
                        .foregroundStyle(PulseTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, canvas.height * 0.3)
            }
            ZenoLiveOverlay(template: template, snapshot: snapshot)
                .scaleEffect(scale)
                .position(x: position.x * canvas.width, y: position.y * canvas.height)
                .accessibilityElement(children: .combine)
                .accessibilityHint(editable ? String(localized: "Drag to move") : "")
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipShape(RoundedRectangle(cornerRadius: editable ? 16 : 0, style: .continuous))
    }
}

/// The overlay itself, laid out for a 360 pt wide picture.
private struct ZenoLiveOverlay: View {
    let template: ZenoLiveTemplate
    let snapshot: ZenoLiveSnapshot?

    private static let glass = Color.black.opacity(0.55)
    private static let rim = Color.white.opacity(0.14)

    var body: some View {
        switch template {
        case .dials: dials
        case .recovery: recovery
        case .strain: strain
        case .heartRate: heartRate
        }
    }

    private var dayText: String {
        snapshot.map { PulseFormat.navDayTitle(offset: $0.day.offset, date: $0.day.date).uppercased() } ?? ""
    }

    /// The three dials on a dark card, as Home's row.
    private var dials: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PulseZenoWordmark(width: 60, height: 10)
                Spacer()
                Text(dayText)
                    .font(PulseType.font(.label))
                    .tracking(1)
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            HStack(spacing: 0) {
                ForEach(dialData, id: \.score) { dial in
                    VStack(spacing: 6) {
                        ZStack {
                            PulseRing(fraction: dial.progress, color: dial.color, diameter: 64, thickness: 5)
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text(dial.value == nil ? "--" : dial.valueText)
                                    .font(PulseType.numeral(20))
                                if let unit = dial.unitText {
                                    Text(unit).font(PulseType.numeral(13))
                                }
                            }
                            .foregroundStyle(PulseTheme.textPrimary)
                        }
                        Text(dial.score.displayName)
                            .font(PulseType.font(.label))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundStyle(PulseTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Self.glass))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Self.rim, lineWidth: 1))
    }

    private var dialData: [PulseDialData] {
        guard let snapshot else {
            return PulseScore.allCases.map { PulseDialData(score: $0, value: nil, state: .noData) }
        }
        return [snapshot.sleep, snapshot.recovery, snapshot.strain]
    }

    /// RECOVERY and the percent in its band's colour.
    private var recovery: some View {
        let dial = snapshot?.recovery
        let color = dial.map { $0.value == nil ? PulseTheme.textTertiary : $0.color } ?? PulseTheme.textTertiary
        return VStack(alignment: .leading, spacing: 2) {
            Text(PulseScore.recovery.displayName)
                .font(PulseType.font(.label))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(PulseTheme.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(dial.flatMap { $0.value == nil ? nil : $0.valueText } ?? "--")
                    .font(PulseType.numeral(52))
                Text(verbatim: "%").font(PulseType.numeral(28))
            }
            .foregroundStyle(color)
            Text(dayText)
                .font(PulseType.font(.label))
                .tracking(1)
                .foregroundStyle(PulseTheme.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Self.glass))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Self.rim, lineWidth: 1))
    }

    /// The Strain ring with its value.
    private var strain: some View {
        let dial = snapshot?.strain ?? PulseDialData(score: .strain, value: nil, state: .noData)
        return VStack(spacing: 8) {
            ZStack {
                PulseRing(fraction: dial.progress, color: PulseTheme.strain, diameter: 112, thickness: 8)
                Text(dial.value == nil ? "--" : dial.valueText)
                    .font(PulseType.numeral(34))
                    .foregroundStyle(PulseTheme.textPrimary)
            }
            Text(PulseScore.strain.displayName)
                .font(PulseType.font(.label))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(PulseTheme.textPrimary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Self.glass))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Self.rim, lineWidth: 1))
    }

    /// The newest heart rate, or an honest dash when there is no current reading.
    private var heartRate: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(PulseTheme.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot?.heartRate.map(String.init) ?? "--")
                    .font(PulseType.numeral(38))
                Text(String(localized: "bpm"))
                    .font(PulseType.numeral(16))
                    .foregroundStyle(PulseTheme.textSecondary)
            }
            .foregroundStyle(PulseTheme.textPrimary)
            if let at = snapshot?.heartRateAt {
                Text(PulseFormat.clock(at))
                    .font(PulseType.font(.label))
                    .foregroundStyle(PulseTheme.textSecondary)
            } else {
                Text(String(localized: "No current reading"))
                    .font(PulseType.font(.label))
                    .foregroundStyle(PulseTheme.textSecondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(Self.glass))
        .overlay(Capsule().strokeBorder(Self.rim, lineWidth: 1))
    }
}

/// The ZENO Live destination, full screen.
struct PulseZenoLiveRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .fullScreen }
    var view: some View { PulseZenoLiveView() }
}

#if DEBUG
/// `--pulse-zeno-live-sample`: a drawn stand-in photo (sky, hills and a lake) for simulator captures, which
/// cannot pick from the library.
enum ZenoLiveSample {
    @MainActor
    static func image() -> UIImage? {
        let view = ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 0.98, green: 0.62, blue: 0.38), Color(red: 0.42, green: 0.36, blue: 0.62),
                                    Color(red: 0.12, green: 0.16, blue: 0.32)], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(red: 1, green: 0.85, blue: 0.6)).frame(width: 140).offset(y: -330)
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 330))
                .foregroundStyle(Color(red: 0.1, green: 0.12, blue: 0.2))
                .offset(y: -40)
            Rectangle().fill(Color(red: 0.16, green: 0.22, blue: 0.36)).frame(height: 150)
        }
        .frame(width: 480, height: 600)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.uiImage
    }
}
#endif
#endif
