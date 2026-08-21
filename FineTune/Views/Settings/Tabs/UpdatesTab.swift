// FineTune/Views/Settings/Tabs/UpdatesTab.swift
import SwiftUI

@MainActor
struct UpdatesTab: View {
    @ObservedObject var updateManager: UpdateManager

    private var lastCheckDescription: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        if let date = updateManager.lastUpdateCheckDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Version \(version) · \(formatter.localizedString(for: date, relativeTo: .now))"
        }
        return "Version \(version) · Never checked"
    }

    private var automaticallyChecksBinding: Binding<Bool> {
        Binding(
            get: { updateManager.automaticallyChecksForUpdates },
            set: { updateManager.automaticallyChecksForUpdates = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsSection("Software Updates") {
                    if updateManager.hasUpdateFeed {
                        SettingsRow(
                            "Automatic updates",
                            description: "Check for new versions automatically"
                        ) {
                            Toggle("", isOn: automaticallyChecksBinding)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .labelsHidden()
                        }
                        SettingsRowDivider()
                        SettingsRow(
                            "Last checked",
                            description: lastCheckDescription
                        ) {
                            Button("Check Now") {
                                updateManager.checkForUpdates()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    } else {
                        SettingsRow(
                            "Updates",
                            description: "\(lastCheckDescription) · This build has no update feed, so it is never replaced automatically. Rebuild from source to update."
                        ) {
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.never)
    }
}
