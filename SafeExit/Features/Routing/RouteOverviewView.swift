import SwiftUI

struct RouteOverviewView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.green)
                        Text("ROUTE OVERVIEW")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(AppTheme.textSec)
                    }

                    // Status card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Safest available route")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.textPri)

                        if let building = viewModel.buildingPackage {
                            Text("\(building.metadata.name) · v\(building.metadata.version)")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSec)
                        }

                        if let route = viewModel.routeResult {
                            HStack(spacing: 10) {
                                Image(systemName: route.destinationKind == .exit
                                      ? "door.left.hand.open" : "figure.roll")
                                    .font(.system(size: 18))
                                    .foregroundStyle(route.destinationKind == .exit
                                                     ? AppTheme.green : AppTheme.amber)
                                Text(route.destinationKind == .exit
                                     ? "Exit route active" : "Refuge route active")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(route.destinationKind == .exit
                                                     ? AppTheme.green : AppTheme.amber)
                            }

                            Text("Distance: \(Int(route.totalDistance))m")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSec)
                        } else if let failure = viewModel.routeFailureMessage {
                            Text(failure)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.red)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))

                    // Room picker
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.green)
                            Text("YOUR LOCATION")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(AppTheme.textSec)
                        }

                        ForEach(viewModel.roomNodes) { node in
                            Button {
                                viewModel.selectStartNode(node.id)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(node.id == viewModel.selectedStartNodeID
                                                  ? AppTheme.greenDim : AppTheme.cardBg3)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "door.left.hand.closed")
                                            .font(.system(size: 15))
                                            .foregroundStyle(node.id == viewModel.selectedStartNodeID
                                                             ? AppTheme.green : AppTheme.textDim)
                                    }

                                    Text(node.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.textPri)

                                    Spacer()

                                    if node.id == viewModel.selectedStartNodeID {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppTheme.green)
                                    }
                                }
                                .padding(12)
                                .background(node.id == viewModel.selectedStartNodeID
                                            ? AppTheme.greenDim.opacity(0.3) : AppTheme.cardBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))

                    // Guidance card
                    if let route = viewModel.routeResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.amber)
                                Text("EVACUATION STEPS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(AppTheme.textSec)
                            }

                            ForEach(route.instructions) { instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(AppTheme.green)
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(instruction.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AppTheme.textPri)
                                        Text(instruction.detail)
                                            .font(.system(size: 12))
                                            .foregroundStyle(AppTheme.textSec)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.cardBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppTheme.textDim)
                            Text("Select a room above to compute the first route.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
    }
}

#Preview {
    RouteOverviewView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
