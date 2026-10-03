#if os(iOS)
import SwiftUI
import UIKit
import PhotosUI
import ImageIO
import StrandAnalytics

/// ZENO Live (WHOOP_UI_SPEC §3.10): today's numbers laid over a photo, to share.
///
/// WHOOP Live overlays live heart rate, Day Strain, Recovery or Sleep on a photo or video; the spec has no
/// capture of it ([U] visuals), so this follows its [Z] outline: pick a photo, choose an overlay (the three
/// dials on a card, Recovery, the Strain ring, or heart rate), drag it into place, and share the result.
/// Everything stays on the phone: the photo comes through the system picker (which needs no library
/// permission), the picture is composed here, and it leaves only through the share sheet. Its numbers are
/// Home's (the same resolvers and the same dial mapping, `PulseDialData.dialContent`), so a value carried
/// from an earlier night says whose it is and a calibrating Recovery reads "--" and CALIBRATING, never as
/// today's number; the heart rate is shown only when a reading is under 15 minutes old. Taking a photo with
/// the camera needs a camera permission the app does not declare, so only the library is offered for now.
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

    private typealias L = PulseExtrasTheme.Live

    var body: some View {
        PulseScreenScaffold(title: String(localized: "ZENO Live"), spacing: 16) {
            GeometryReader { geo in
                let canvas = canvasSize(fitting: geo.size)
                composite(canvas: canvas, editable: true)
                    .frame(width: canvas.width, height: canvas.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: L.canvasHeight)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ZenoLiveTemplate.allCases) { t in
                        PulseFilterChip(title: t.title, isSelected: template == t) { template = t }
                    }
                }
            }
            .scrollClipDisabled()

            // Side by side while both labels fit at half the width each, stacked once they do not, so a
            // large text size never cuts "CHANGE PHOTO" short.
            ViewThatFits(in: .horizontal) {
                ExtrasEqualWidthRow(spacing: PulseTheme.Layout.gridGap) { photoButton; shareButton }
                VStack(spacing: PulseTheme.Layout.gridGap) { photoButton; shareButton }
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
                guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                // Decode off the main actor, and no larger than the picture can be exported at.
                let image = await Task.detached(priority: .userInitiated) {
                    Self.downsampled(data, maxPixels: L.exportMaxPixels)
                }.value
                if let image { photo = image }
            }
        }
        #if DEBUG
        .onAppear {
            // `--pulse-zeno-live-sample` draws a stand-in photo and `--pulse-zeno-live-template <name>` picks
            // the overlay, for simulator captures (simctl can neither pick a photo nor tap).
            let args = CommandLine.arguments
            if photo == nil, args.contains("--pulse-zeno-live-sample") {
                photo = ZenoLiveSample.image()
            }
            if let i = args.firstIndex(of: "--pulse-zeno-live-template"), i + 1 < args.count,
               let t = ZenoLiveTemplate(rawValue: args[i + 1]) {
                template = t
            }
        }
        #endif
    }

    private var photoButton: some View {
        PhotosPicker(selection: $pick, matching: .images, photoLibrary: .shared()) {
            Label(photo == nil ? String(localized: "Choose photo") : String(localized: "Change photo"),
                  systemImage: "photo")
        }
        .buttonStyle(.pulseOutlineWhite)
    }

    private var shareButton: some View {
        Button { share() } label: {
            Label(String(localized: "Share"), systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.pulseFilledWhite)
        .disabled(photo == nil || exporting)
        .opacity(photo == nil ? 0.4 : 1)
    }

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

    /// Compose the picture at the photo's own width, up to `exportMaxPixels`, and offer it through the share
    /// sheet. The view is rendered here (ImageRenderer needs the main actor); the JPEG is encoded and written
    /// off it, then the sheet is presented back on it.
    private func share() {
        guard let photo, !exporting else { return }
        exporting = true
        let canvas = canvasSize(fitting: CGSize(width: L.layoutWidth, height: 10_000))
        let pixelWidth = min(photo.size.width * photo.scale, L.exportMaxPixels)
        let renderer = ImageRenderer(content: ZenoLiveComposite(photo: photo, template: template, snapshot: snapshot,
                                                                position: position, canvas: canvas, editable: false)
            .frame(width: canvas.width, height: canvas.height)
            .environment(\.colorScheme, .dark))
        renderer.scale = max(1, pixelWidth / canvas.width)
        guard let image = renderer.uiImage else {
            exporting = false
            return
        }
        Task {
            let url = await Task.detached(priority: .userInitiated) { () -> URL? in
                guard let data = image.jpegData(compressionQuality: L.jpegQuality) else { return nil }
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("ZENO-Live.jpg")
                do { try data.write(to: url, options: .atomic) } catch { return nil }
                return url
            }.value
            exporting = false
            if let url { PulseExtrasShareSheet.present(url) }
        }
    }

    /// `data` decoded as an image no wider or taller than `maxPixels`, its orientation applied (ImageIO's
    /// thumbnailer, which never decodes the full-size picture).
    nonisolated static func downsampled(_ data: Data, maxPixels: CGFloat) -> UIImage? {
        let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary)
        guard let source else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}

/// Buttons side by side at equal widths, whose ideal width is that of the widest one times their number, so
/// a `ViewThatFits` only keeps them in a row when every label fits its equal share (the shared
/// `PulseButtonRow` measures their natural widths, then splits the row evenly, and can cut the longer one).
/// `allowedShrink` is how far a label may scale down to fit (Pulse's buttons allow 0.8 on their text).
struct ExtrasEqualWidthRow: Layout {
    var spacing: CGFloat
    var allowedShrink: CGFloat = 0.85

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ideals = subviews.map { $0.sizeThatFits(.unspecified) }
        let count = CGFloat(max(1, subviews.count))
        let ideal = (ideals.map(\.width).max() ?? 0) * allowedShrink * count + spacing * (count - 1)
        let height = ideals.map(\.height).max() ?? 0
        return CGSize(width: proposal.width ?? ideal, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let count = CGFloat(max(1, subviews.count))
        let width = (bounds.width - spacing * (count - 1)) / count
        for (i, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + CGFloat(i) * (width + spacing), y: bounds.midY),
                          anchor: .leading, proposal: ProposedViewSize(width: width, height: bounds.height))
        }
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

    private typealias L = PulseExtrasTheme.Live

    /// Overlays are drawn for a 360 pt wide picture and scaled with it, so the exported photo matches.
    private var scale: CGFloat { canvas.width / L.layoutWidth }

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
                RoundedRectangle(cornerRadius: L.canvasRadius, style: .continuous)
                    .fill(PulseTheme.card)
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: L.placeholderGlyphSize, weight: .light))
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
        .clipShape(RoundedRectangle(cornerRadius: editable ? L.canvasRadius : 0, style: .continuous))
    }
}

/// The overlay itself, laid out for a 360 pt wide picture. Each number comes through Home's dial mapping
/// (`PulseDialData.dialContent`): a carried value carries its "Last night · Oct 2" line, a calibrating
/// Recovery reads "--" with CALIBRATING and an empty ring, and nothing is printed as today's that is not.
private struct ZenoLiveOverlay: View {
    let template: ZenoLiveTemplate
    let snapshot: ZenoLiveSnapshot?

    private typealias L = PulseExtrasTheme.Live

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

    private func content(_ score: PulseScore) -> PulseDialContent {
        guard let snapshot else { return PulseDialData(score: score, value: nil, state: .noData).dialContent() }
        switch score {
        case .sleep: return snapshot.sleep.dialContent()
        case .recovery: return snapshot.recovery.dialContent()
        case .strain: return snapshot.strain.dialContent()
        }
    }

    /// A label in the card's caps.
    private func caps(_ text: String, color: Color) -> some View {
        Text(text)
            .font(PulseType.font(.label))
            .tracking(L.labelTracking)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// The three dials on a dark card, as Home's row, each with its state line when it has one.
    private var dials: some View {
        let contents = PulseScore.allCases.map(content)
        let anyCaption = contents.contains { $0.caption != nil }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                PulseZenoWordmark(width: L.wordmark.width, height: L.wordmark.height)
                Spacer()
                caps(dayText, color: PulseTheme.textSecondary)
            }
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(contents.enumerated()), id: \.offset) { _, dial in
                    VStack(spacing: 6) {
                        ZStack {
                            PulseRing(fraction: dial.fraction, color: dial.color, diameter: L.dialDiameter,
                                      thickness: L.dialStroke)
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text(dial.valueText)
                                    .font(PulseType.numeral(L.dialValueSize))
                                if let unit = dial.unitText {
                                    Text(unit).font(PulseType.numeral(L.dialUnitSize))
                                }
                            }
                            .foregroundStyle(dial.isPlaceholder ? PulseTheme.textDisabled : PulseTheme.textPrimary)
                        }
                        caps(dial.label, color: PulseTheme.textPrimary)
                        if anyCaption {
                            caps(dial.caption ?? " ", color: PulseTheme.textTertiary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(L.cardPadding)
        .frame(width: L.dialsCardWidth)
        .background(RoundedRectangle(cornerRadius: L.cardRadius, style: .continuous).fill(L.glass))
        .overlay(RoundedRectangle(cornerRadius: L.cardRadius, style: .continuous).strokeBorder(L.rim, lineWidth: 1))
    }

    /// RECOVERY and the percent in its band's colour; the line under it says whose it is when it is not
    /// today's own (carried, or calibrating).
    private var recovery: some View {
        let dial = content(.recovery)
        return VStack(alignment: .leading, spacing: 2) {
            caps(dial.label, color: PulseTheme.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(dial.valueText)
                    .font(PulseType.numeral(L.recoveryValueSize))
                Text(verbatim: dial.unitText ?? "%").font(PulseType.numeral(L.recoveryUnitSize))
            }
            .foregroundStyle(dial.isPlaceholder ? PulseTheme.textTertiary : dial.color)
            caps(dial.caption ?? dayText, color: PulseTheme.textSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, L.cardPadding)
        .background(RoundedRectangle(cornerRadius: L.cardRadius, style: .continuous).fill(L.glass))
        .overlay(RoundedRectangle(cornerRadius: L.cardRadius, style: .continuous).strokeBorder(L.rim, lineWidth: 1))
    }

    /// The Strain ring with its value (Strain is always the day's own, live).
    private var strain: some View {
        let dial = content(.strain)
        return VStack(spacing: 8) {
            ZStack {
                PulseRing(fraction: dial.fraction, color: PulseTheme.strain, diameter: L.strainDiameter,
                          thickness: L.strainStroke)
                Text(dial.valueText)
                    .font(PulseType.numeral(L.strainValueSize))
                    .foregroundStyle(dial.isPlaceholder ? PulseTheme.textDisabled : PulseTheme.textPrimary)
            }
            caps(dial.label, color: PulseTheme.textPrimary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: L.strainCardRadius, style: .continuous).fill(L.glass))
        .overlay(RoundedRectangle(cornerRadius: L.strainCardRadius, style: .continuous)
            .strokeBorder(L.rim, lineWidth: 1))
    }

    /// The newest heart rate, or an honest dash when there is no current reading.
    private var heartRate: some View {
        HStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: L.heartGlyphSize, weight: .regular))
                .foregroundStyle(PulseTheme.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snapshot?.heartRate.map(String.init) ?? "--")
                    .font(PulseType.numeral(L.heartValueSize))
                Text(String(localized: "bpm"))
                    .font(PulseType.numeral(L.heartUnitSize))
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
        .background(Capsule().fill(L.glass))
        .overlay(Capsule().strokeBorder(L.rim, lineWidth: 1))
    }
}

/// The ZENO Live destination, full screen.
struct PulseZenoLiveRoute: PulseScreenRoute {
    var presentation: PulsePresentation { .fullScreen }
    var view: some View { PulseZenoLiveView() }
}

#if DEBUG
/// `--pulse-zeno-live-sample`: a drawn stand-in photo (sky, hills and a lake) for simulator captures, which
/// cannot pick from the library. Its colours and sizes are the picture's content, not the screen's, so they
/// stay here rather than in the theme.
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
