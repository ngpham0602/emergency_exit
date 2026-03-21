import SwiftUI

struct LocationSelectionView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.green)
                Text("YOUR LOCATION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
                Spacer()
                if let node = viewModel.currentStartNode {
                    Text(node.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.greenDim)
                        .clipShape(Capsule())
                }
            }

            Picker("Room", selection: Binding(
                get: { viewModel.selectedStartNodeID ?? "" },
                set: { viewModel.selectStartNode($0) }
            )) {
                ForEach(viewModel.roomNodes) { node in
                    Text(node.name).tag(node.id)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.green)
        }
        .padding(16)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
    }
}

#Preview {
    LocationSelectionView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
        .padding()
        .background(AppTheme.bg)
}
