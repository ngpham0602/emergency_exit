import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        Form {
            Section("Accessibility") {
                Toggle("Wheelchair-safe routing", isOn: $viewModel.accessibilityMode)
                Toggle("Audio guidance placeholder", isOn: $viewModel.prefersAudioGuidance)
            }

            Section("Scaffold notes") {
                Text("This project is seeded with one building package, a local routing engine, and simulated hazards. Add QR scanning, sync, and map rendering as separate features later.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
