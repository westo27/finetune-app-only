// FineTuneTests/AppOnlyModeTests.swift
// Covers the `showAudioDevices` gate that turns this build into an app-audio
// mixer: the flag's default and decoding, the styles it withdraws, keyboard
// navigation with no device rows, and the engine reporting every app as
// follow-system-default single-device with no AutoEQ while it is off.

import Testing
import Foundation
import AppKit
import AudioToolbox
@testable import FineTune

// MARK: - The Flag

@Suite("AppSettings.showAudioDevices")
@MainActor
struct ShowAudioDevicesFlagTests {
    @Test("Defaults to off, so a fresh install manages apps only")
    func defaultsOff() {
        #expect(AppSettings().showAudioDevices == false)
    }

    @Test("Settings written before the flag existed decode to off")
    func absentKeyDecodesOff() throws {
        // A settings file from an earlier build: every other key present, no
        // showAudioDevices. decodeIfPresent must not throw or default to true.
        let json = """
        {"launchAtLogin":true,"defaultNewAppVolume":0.8,"lockInputDevice":true}
        """
        let decoded = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
        #expect(decoded.showAudioDevices == false)
        #expect(decoded.launchAtLogin == true)  // sanity: the rest still decoded
    }

    @Test("An explicit true survives a round-trip")
    func explicitTrueRoundTrips() throws {
        var settings = AppSettings()
        settings.showAudioDevices = true
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded.showAudioDevices == true)
    }
}

// MARK: - Menu Bar Icon Style

@Suite("MenuBarIconStyle device-management gating")
struct MenuBarIconStyleGatingTests {
    @Test("The device style is not offered when device management is off")
    func deviceStyleWithdrawn() {
        let offered = MenuBarIconStyle.selectableCases(deviceManagementEnabled: false)
        #expect(!offered.contains(.device))
        #expect(offered.count == MenuBarIconStyle.allCases.count - 1)
    }

    @Test("Every style is offered when device management is on")
    func allStylesOffered() {
        #expect(MenuBarIconStyle.selectableCases(deviceManagementEnabled: true) == MenuBarIconStyle.allCases)
    }

    @Test("A persisted device style resolves to speaker rather than a device icon")
    func persistedDeviceStyleResolves() {
        #expect(MenuBarIconStyle.device.resolved(deviceManagementEnabled: false) == .speaker)
        #expect(MenuBarIconStyle.device.resolved(deviceManagementEnabled: true) == .device)
    }

    @Test("Other styles are never substituted")
    func otherStylesUnchanged() {
        for style in MenuBarIconStyle.allCases where style != .device {
            #expect(style.resolved(deviceManagementEnabled: false) == style)
            #expect(style.resolved(deviceManagementEnabled: true) == style)
        }
    }
}

// MARK: - Keyboard Navigation

@Suite("PopupKeyboardNavModel with no device rows")
@MainActor
struct AppOnlyNavigationTests {
    @Test("Arrow navigation walks apps only")
    func orderHoldsAppsOnly() {
        let model = PopupKeyboardNavModel()
        model.syncOrder(
            activeDevices: [],
            appPersistenceIDs: ["com.test.a", "com.test.b"],
            isEditingPriority: false
        )
        #expect(model.orderedRowIDs == [
            .app(persistenceID: "com.test.a"),
            .app(persistenceID: "com.test.b")
        ])
    }

    @Test("First keypress focuses the first app, not a default device row")
    func defaultFocusFallsBackToFirstApp() {
        let model = PopupKeyboardNavModel()
        model.syncOrder(
            activeDevices: [],
            appPersistenceIDs: ["com.test.a", "com.test.b"],
            isEditingPriority: false
        )
        // nil mirrors MenuBarPopupView.currentDefaultDeviceUID() while gated off.
        #expect(model.defaultFocus(defaultOutputUID: nil) == .app(persistenceID: "com.test.a"))
        // Even if a UID leaks through, there is no such row to focus.
        #expect(model.defaultFocus(defaultOutputUID: "dev1") == .app(persistenceID: "com.test.a"))
    }
}

// MARK: - Engine Routing Gate

@Suite("AudioEngine routing gate")
@MainActor
struct AudioEngineRoutingGateTests {
    @Test("Apps report as following system default despite a persisted routing")
    func persistedRoutingIsIgnoredWhileGated() {
        let (engine, settings, app) = makeEngine()
        settings.setDeviceRouting(for: app.persistenceIdentifier, deviceUID: "AirPodsProDevice")

        #expect(engine.deviceRoutingEnabled == false)
        #expect(engine.isFollowingDefault(for: app) == true)

        // The routing is still on disk, so switching device management back on
        // restores it rather than silently discarding what the user chose.
        settings.appSettings.showAudioDevices = true
        #expect(engine.isFollowingDefault(for: app) == false)
        #expect(settings.getDeviceRouting(for: app.persistenceIdentifier) == "AirPodsProDevice")
    }

    @Test("A persisted multi-device fan-out reads as single-device while gated")
    func persistedMultiModeIsIgnoredWhileGated() {
        let (engine, settings, app) = makeEngine()
        settings.setDeviceSelectionMode(for: app.persistenceIdentifier, to: .multi)
        // getDeviceSelectionMode reads in-memory state, so hydrate it from the
        // persisted value the way applyPersistedSettings does on app discovery.
        _ = engine.volumeState.loadSavedDeviceSelectionMode(
            for: app.id,
            identifier: app.persistenceIdentifier
        )

        #expect(engine.getDeviceSelectionMode(for: app) == .single)

        settings.appSettings.showAudioDevices = true
        #expect(engine.getDeviceSelectionMode(for: app) == .multi)
    }

    @Test("AutoEQ correction is withheld from the chain, not merely hidden")
    func autoEQSelectionWithheldWhileGated() {
        let (engine, settings, _) = makeEngine()
        settings.setAutoEQSelection(
            for: "AirPodsProDevice",
            to: AutoEQSelection(profileID: "profile-123", isEnabled: true)
        )

        #expect(engine.getAutoEQSelection(for: "AirPodsProDevice") == nil)

        settings.appSettings.showAudioDevices = true
        #expect(engine.getAutoEQSelection(for: "AirPodsProDevice")?.profileID == "profile-123")
    }

    @Test("Pinned inactive apps report follow-default too")
    func inactiveAppsFollowDefaultWhileGated() {
        let (engine, settings, _) = makeEngine()
        let identifier = "com.test.pinned"
        settings.setDeviceRouting(for: identifier, deviceUID: "AirPodsProDevice")

        #expect(engine.getDeviceRoutingForInactive(identifier: identifier) == nil)
        #expect(engine.isFollowingDefaultForInactive(identifier: identifier) == true)
        #expect(engine.getDeviceSelectionModeForInactive(identifier: identifier) == .single)
        #expect(engine.getSelectedDeviceUIDsForInactive(identifier: identifier).isEmpty)

        settings.appSettings.showAudioDevices = true
        #expect(engine.getDeviceRoutingForInactive(identifier: identifier) == "AirPodsProDevice")
    }

    private func makeEngine() -> (AudioEngine, SettingsManager, AudioApp) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let settings = SettingsManager(directory: tempDir)
        let deviceMonitor = MockAudioDeviceMonitor()
        let engine = AudioEngine(
            permission: AudioRecordingPermission(),
            settingsManager: settings,
            autoEQProfileManager: AutoEQProfileManager(loadsCatalog: false),
            deviceProvider: deviceMonitor,
            deviceVolumeMonitor: MockDeviceVolumeProviding(deviceMonitor: deviceMonitor),
            startMonitorsAutomatically: false
        )
        let app = AudioApp(
            id: 51515,
            processObjectIDs: [],
            name: "TestApp",
            icon: NSImage(systemSymbolName: "speaker.wave.2", accessibilityDescription: nil) ?? NSImage(),
            bundleID: "com.test.appOnlyMode"
        )
        return (engine, settings, app)
    }
}
