import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @State private var criticalAlerts     = true
    @State private var liveLocation       = true
    @State private var biometricLock      = false
    @State private var showSignOutConfirm = false
    @State private var showFirebaseTest   = false
    @State private var showSendEmergency  = false

    private let safetyContacts: [SafetyContact] = [
        SafetyContact(name: "Emergency Response", role: "Security",       icon: "shield.fill"),
        SafetyContact(name: "Building Warden",    role: "Floor Warden",   icon: "person.badge.shield.checkmark.fill"),
        SafetyContact(name: "Fire Department",    role: "First Response", icon: "flame.fill"),
    ]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Header bar
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                            Image(systemName: "shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.bg)
                        }
                        Text("Profile")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.textPri)
                        Spacer()
                        Menu {
                            Button("Edit Profile") {}
                            Button("Export Safety Data") {}
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    // Avatar + name
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(AppTheme.cardBg2)
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Text(initials(from: auth.userName))
                                        .font(.system(size: 30, weight: .black))
                                        .foregroundStyle(AppTheme.textSec)
                                )

                            Circle()
                                .fill(AppTheme.green)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundStyle(AppTheme.bg)
                                )
                        }

                        Text(auth.userName)
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(AppTheme.textPri)

                        Text(auth.userRole.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .padding(.bottom, 24)

                    // Stats row
                    HStack(spacing: 0) {
                        ProfileStat(value: "\(safetyContacts.count)", label: "CONTACTS")
                        Divider().frame(width: 1, height: 40).background(AppTheme.divider)
                        ProfileStat(value: "100%", label: "READY")
                        Divider().frame(width: 1, height: 40).background(AppTheme.divider)
                        ProfileStat(value: "A+", label: "SCORE")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    VStack(spacing: 16) {

                        // Emergency protocols (security only)
                        if auth.userRole == .security {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(icon: "exclamationmark.triangle.fill",
                                              label: "EMERGENCY PROTOCOLS",
                                              iconColor: AppTheme.red)

                                Text("Instantly broadcast your SOS code to all safety contacts and building security.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textSec)
                                    .padding(.horizontal, 2)

                                Button { showSendEmergency = true } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "megaphone.fill")
                                            .font(.system(size: 16))
                                        Text("Send Emergency Code")
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .darkCard()
                        }

                        // Safety contacts
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SectionHeader(icon: "phone.fill", label: "SAFETY CONTACTS", iconColor: AppTheme.green)
                                Spacer()
                                Text("Manage")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppTheme.green)
                            }

                            ForEach(safetyContacts) { contact in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppTheme.cardBg3)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: contact.icon)
                                                .font(.system(size: 16))
                                                .foregroundStyle(AppTheme.textSec)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AppTheme.textPri)
                                        Text(contact.role)
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppTheme.green)
                                    }

                                    Spacer()

                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppTheme.textSec)
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(AppTheme.textSec)
                                    }
                                }
                                .padding(12)
                                .background(AppTheme.cardBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .darkCard()

                        // Preferences (connected to AppViewModel)
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(icon: "gearshape.fill", label: "PREFERENCES", iconColor: AppTheme.textSec)

                            PrefToggleRow(
                                icon: "bell.badge.fill",
                                title: "Critical Alerts",
                                subtitle: "Receive immediate audio-visual warnings during evacuations.",
                                isOn: $criticalAlerts
                            )

                            Divider().background(AppTheme.divider)

                            PrefToggleRow(
                                icon: "location.fill",
                                title: "Live Location",
                                subtitle: "Allow real-time tracking for building rescue services.",
                                isOn: $liveLocation
                            )

                            Divider().background(AppTheme.divider)

                            PrefToggleRow(
                                icon: "figure.roll",
                                title: "Wheelchair Routing",
                                subtitle: "Only use wheelchair-accessible paths and avoid stairs.",
                                isOn: $viewModel.accessibilityMode
                            )

                            Divider().background(AppTheme.divider)

                            PrefToggleRow(
                                icon: "speaker.wave.3.fill",
                                title: "Audio Guidance",
                                subtitle: "Spoken turn-by-turn instructions during evacuation.",
                                isOn: $viewModel.prefersAudioGuidance
                            )

                            Divider().background(AppTheme.divider)

                            PrefToggleRow(
                                icon: "faceid",
                                title: "Biometric Lock",
                                subtitle: "Secure emergency actions with FaceID or Fingerprint.",
                                isOn: $biometricLock
                            )
                        }
                        .darkCard()

                        // Building info
                        if let building = viewModel.buildingPackage {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(icon: "building.2.fill", label: "BUILDING INFO", iconColor: AppTheme.textSec)
                                buildingInfoRow(label: "Name",    value: building.metadata.name)
                                buildingInfoRow(label: "Package", value: "v\(building.metadata.version)")
                                buildingInfoRow(label: "Floors",  value: "\(building.floors.count)")
                                buildingInfoRow(label: "Exits",   value: "\(building.exits.filter { $0.status == .available }.count) available")
                                buildingInfoRow(label: "Status",
                                                value: viewModel.activeHazards.isEmpty ? "All Clear" : "\(viewModel.activeHazards.count) hazard(s) active",
                                                valueColor: viewModel.activeHazards.isEmpty ? AppTheme.green : AppTheme.red)
                            }
                            .darkCard()
                        }

                        // Database test
                        Button { showFirebaseTest = true } label: {
                            HStack {
                                Image(systemName: "bolt.horizontal.circle")
                                    .font(.system(size: 16))
                                Text("Firebase DB Test")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textDim)
                            }
                            .foregroundStyle(AppTheme.textPri)
                            .padding(16)
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                        }

                        // Sign out
                        Button { showSignOutConfirm = true } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Sign Out of SafeExit")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textDim)
                            }
                            .foregroundStyle(AppTheme.textPri)
                            .padding(16)
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                        }

                        Text("SAFEEXIT · BUILD 2401")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textDim)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showFirebaseTest) { FirebaseTestView() }
        .sheet(isPresented: $showSendEmergency) {
            SendEmergencyView()
                .environmentObject(viewModel)
                .environmentObject(auth)
                .presentationBackground(AppTheme.bg)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { auth.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your evacuation routes.")
        }
    }

    private func initials(from name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    private func buildingInfoRow(label: String, value: String, valueColor: Color = AppTheme.textSec) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSec)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sub-views

private struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AppTheme.green)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionHeader: View {
    let icon: String
    let label: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)
        }
    }
}

private struct PrefToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.cardBg3)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textSec)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPri)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSec)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(AppTheme.green)
                .labelsHidden()
        }
    }
}

private struct SafetyContact: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let icon: String
}

// MARK: - Dark card modifier

private extension View {
    func darkCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
        .environmentObject(AuthViewModel())
}
