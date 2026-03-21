import SwiftUI

struct FirebaseTestView: View {
    @State private var readMessage = ""
    @State private var writeMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {

            Text("Firebase Test")
                .font(.title).bold()

            // ── WRITE TEST ──────────────────────────
            Button {
                Task { await sendTestData() }
            } label: {
                Label("Send Test Building", systemImage: "arrow.up.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            if !writeMessage.isEmpty {
                Text(writeMessage)
                    .foregroundColor(
                        writeMessage.contains("✅") ? .green : .red
                    )
                    .multilineTextAlignment(.center)
            }

            Divider()

            // ── READ TEST ───────────────────────────
            Button {
                Task { await readTestData() }
            } label: {
                Label("Read From Database", systemImage: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            if !readMessage.isEmpty {
                Text(readMessage)
                    .foregroundColor(
                        readMessage.contains("✅") ? .green : .red
                    )
                    .multilineTextAlignment(.center)
            }

            if isLoading {
                ProgressView()
            }
        }
        .padding()
    }

    // ── SEND DATA TO FIREBASE ──────────────────────
    func sendTestData() async {
        isLoading = true
        writeMessage = ""

        let testBuilding = Building(
            id: nil,
            name: "Test Building Sydney",
            address: "123 Test Street Sydney",
            type: "mall",
            verified: false,
            uploadCount: 1,
            confidenceScore: 0.5
        )

        do {
            let newId = try await FirestoreService.shared.createBuilding(testBuilding)
            writeMessage = "✅ Saved! Document ID: \(newId)"
        } catch {
            writeMessage = "❌ Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // ── READ DATA FROM FIREBASE ────────────────────
    func readTestData() async {
        isLoading = true
        readMessage = ""

        do {
            let buildings = try await FirestoreService.shared.fetchBuildings()

            if buildings.isEmpty {
                readMessage = "⚠️ No buildings found in database"
            } else {
                let names = buildings.map { $0.name }.joined(separator: "\n")
                readMessage = "✅ Found \(buildings.count) building(s):\n\(names)"
            }
        } catch {
            readMessage = "❌ Error: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
