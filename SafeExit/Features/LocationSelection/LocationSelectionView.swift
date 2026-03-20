import SwiftUI

struct LocationSelectionView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        GroupBox("Current location") {
            VStack(alignment: .leading, spacing: 16) {
            Picker("Room", selection: Binding(
                get: { viewModel.selectedStartNodeID ?? "" },
                set: { viewModel.selectStartNode($0) }
            )) {
                ForEach(viewModel.roomNodes) { node in
                    Text(node.name).tag(node.id)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("QR anchors")
                    .font(.headline)
                Text("The scaffold includes a seeded QR mapping file. Replace this with an AVFoundation scanner when you add the live scan flow.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            }
        }
    }
}
