// FineTune/Utilities/AppInfo.swift
import Foundation

/// Single source of truth for the product's user-facing name.
///
/// The name appears in three kinds of place, and they must agree:
/// UI copy, the `FluidMenuBarExtra` title, and the accessibility title used to
/// find the status-item button again (`MenuBarPopupController`,
/// `MenuBarIconCoordinator`). A literal in one of those without the others
/// silently breaks the popup hotkey or the icon crossfade, so they all read
/// this constant.
///
/// Deliberately *not* the bundle identifier, the `finetune://` URL scheme, the
/// Application Support directory, or the `FineTune-<pid>` aggregate device
/// names. Those are identifiers: renaming them would abandon existing settings
/// and orphan aggregates left by earlier builds.
nonisolated enum AppInfo {
    /// Product name as shown to the user.
    static let displayName = "AppMixer"
}
