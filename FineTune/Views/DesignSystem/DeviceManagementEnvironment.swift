// FineTune/Views/DesignSystem/DeviceManagementEnvironment.swift
import SwiftUI

/// Environment key mirroring `AppSettings.showAudioDevices` down the view tree.
///
/// Carried through the environment rather than threaded as a parameter because
/// the consumers are deep inside row bodies (`AppRowControls`) whose
/// initialisers are already wide, and whose call sites are duplicated across the
/// active and pinned-inactive paths plus the preview and test fixtures. An
/// environment value keeps those signatures untouched.
///
/// Defaults to `false` so any view rendered outside an injected root — previews,
/// unit tests instantiating a row directly — matches the shipping app-only
/// behaviour instead of silently showing device controls.
private struct DeviceManagementEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// True when the user has opted back into device management (device list,
    /// device volume sliders, input tab, per-app output routing, AutoEQ).
    var deviceManagementEnabled: Bool {
        get { self[DeviceManagementEnabledKey.self] }
        set { self[DeviceManagementEnabledKey.self] = newValue }
    }
}
