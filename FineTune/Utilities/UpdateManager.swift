// FineTune/Utilities/UpdateManager.swift
import Foundation
import Combine
import Sparkle

/// Manages app updates via Sparkle
@MainActor
final class UpdateManager: NSObject, ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false

    override init() {
        // Create the updater controller without auto-starting (prevents popup on launch)
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()

        // Start updater to enable manual checks, but don't trigger auto-check UI
        try? updaterController.updater.start()

        // This build has no appcast: SUFeedURL was removed from Info.plist so a
        // check can't pull the upstream FineTune release over the top of it.
        // Automatic checks are forced off to match, and the Updates tab reflects
        // it. Restoring updates means adding a feed URL and its EdDSA key back.
        updaterController.updater.automaticallyChecksForUpdates = false

        // Observe when updates can be checked
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .assign(to: &$canCheckForUpdates)
    }

    /// True when no appcast is configured, so update checks can't do anything.
    var hasUpdateFeed: Bool {
        Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
    }

    /// Check for updates manually
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    /// Whether automatic update checks are enabled
    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    /// Whether to automatically download updates
    var automaticallyDownloadsUpdates: Bool {
        get { updaterController.updater.automaticallyDownloadsUpdates }
        set { updaterController.updater.automaticallyDownloadsUpdates = newValue }
    }

    /// Last update check date
    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }
}
