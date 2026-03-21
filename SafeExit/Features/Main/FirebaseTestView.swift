import SwiftUI

struct FirebaseTestView: View {
    @State private var message = "Connecting to Firebase..."
    @State private var buildingName = ""
    @State private var floorLabel = ""

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("SafeExit — Database Test")
                .font(.title2).bold()

            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !buildingName.isEmpty {
                VStack(spacing: 8) {
                    Label("Firebase Connected!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .bold()
                    Text("Building: \(buildingName)")
                    Text("Floor: \(floorLabel)")
                }
                .padding()
                .background(Color.green.opacity(0.15))
                .cornerRadius(12)
            }
        }
        .padding()
        .task {
            do {
                let buildings = try await FirestoreService.shared.fetchBuildings()
                guard let first = buildings.first, let id = first.id else {
                    message = "No buildings found — add test data in Firebase console"
                    return
                }
                buildingName = first.name
                let floors = try await FirestoreService.shared.fetchFloors(buildingId: id)
                floorLabel = floors.first?.floorLabel ?? "No floors found"
                message = "✅ Database working perfectly"
            } catch {
                message = "❌ Error: \(error.localizedDescription)"
            }
        }
    }
}
