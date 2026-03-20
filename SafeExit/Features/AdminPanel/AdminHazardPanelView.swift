import SwiftUI

struct AdminHazardPanelView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        List {
            Section("Simulation controls") {
                Button("Reset hazard state") {
                    viewModel.resetHazards()
                }
            }

            if let building = viewModel.buildingPackage {
                Section("Demo hazards") {
                    ForEach(building.hazardTemplates) { hazard in
                        Toggle(
                            isOn: Binding(
                                get: { viewModel.activeHazards.contains(where: { $0.id == hazard.id }) },
                                set: { viewModel.toggleHazard(hazard.id, enabled: $0) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hazard.title)
                                Text(hazard.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Active route state") {
                Text(viewModel.routeResult?.destinationKind == .refugePoint ? "Fallback to refuge point" : "Exit route available")
                Text("Hazards active: \(viewModel.activeHazards.count)")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Hazard Panel")
    }
}
