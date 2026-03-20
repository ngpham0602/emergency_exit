import SwiftUI

struct RouteOverviewView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                LocationSelectionView()
                guidanceCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("SafeExit")
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safest available route")
                .font(.title2.bold())

            if let building = viewModel.buildingPackage {
                Text("\(building.metadata.name) · v\(building.metadata.version)")
                    .foregroundStyle(.secondary)
            }

            if let route = viewModel.routeResult {
                Label(
                    route.destinationKind == .exit ? "Exit route active" : "Refuge route active",
                    systemImage: route.destinationKind == .exit ? "door.left.hand.open" : "figure.wave"
                )
                .font(.headline)
                .foregroundStyle(route.destinationKind == .exit ? .green : .orange)

                Text("Distance: \(route.totalDistance.formatted(.number.precision(.fractionLength(0))))m")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let failure = viewModel.routeFailureMessage {
                Text(failure)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var guidanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Emergency guidance")
                    .font(.title3.bold())
                Spacer()
                NavigationLink("Full screen") {
                    EmergencyGuidanceView()
                }
            }

            if let route = viewModel.routeResult {
                ForEach(route.instructions) { instruction in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(instruction.title)
                            .font(.headline)
                        Text(instruction.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.red.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                Text("Select a room to compute the first route.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
