import SwiftUI

struct EmergencyGuidanceView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let route = viewModel.routeResult {
                Text(route.destinationKind == .exit ? "EVACUATE" : "GO TO REFUGE")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Image(systemName: route.destinationKind == .exit ? "arrow.up.right.circle.fill" : "figure.roll")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundStyle(.white)

                Text(route.instructions.first?.detail ?? "Follow the next instruction.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(route.instructions.prefix(3)) { instruction in
                        Text("• \(instruction.title)")
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }

                Spacer()
            } else {
                Text("No route loaded.")
                    .foregroundStyle(.white)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.red, Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
