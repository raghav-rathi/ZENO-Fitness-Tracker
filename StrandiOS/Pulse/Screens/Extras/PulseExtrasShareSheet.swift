#if os(iOS)
import SwiftUI
import UIKit

/// Presents the share sheet for a rendered image from the top-most controller. Saving to Photos is
/// excluded: the app does not declare NSPhotoLibraryAddUsageDescription, and "Save Image" would end the
/// app without it (Files, AirDrop and Messages still take the PNG).
enum PulseExtrasShareSheet {
    @MainActor
    static func present(_ url: URL) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first,
              var presenter = scene.windows.first(where: \.isKeyWindow)?.rootViewController
                ?? scene.windows.first?.rootViewController else { return }
        while let next = presenter.presentedViewController, !next.isBeingDismissed { presenter = next }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.excludedActivityTypes = [.saveToCameraRoll]
        sheet.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = presenter.view
            pop.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        presenter.present(sheet, animated: true)
    }
}
#endif
