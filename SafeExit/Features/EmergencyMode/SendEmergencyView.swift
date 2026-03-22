import SwiftUI

struct SendEmergencyView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: EmergencyType?
    @State private var isSending = false
    @State private var didSend = false
    @State private var confirmSend = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Nav bar
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Spacer()
                        Text("SEND EMERGENCY ALERT")
                            .font(.system(size: 13, weight: .black))
                            .tracking(1)
                            .foregroundStyle(.white)
                        Spacer()
                        // balance spacer
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    // Warning icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.red.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Circle()
                            .fill(AppTheme.red.opacity(0.08))
                            .frame(width: 116, height: 116)
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.red)
                    }
                    .padding(.bottom, 16)

                    Text("BROADCAST EMERGENCY")
                        .font(.system(size: 22, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .padding(.bottom, 6)

                    Text("All users will receive a critical alert\nthat bypasses silent mode.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 28)

                    // Type picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT THREAT TYPE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.horizontal, 4)

                        ForEach(EmergencyType.allCases) { type in
                            emergencyTypeRow(type)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // Send button
                    if didSend {
                        // Success state
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(AppTheme.green)
                            Text("ALERT SENT")
                                .font(.system(size: 16, weight: .black))
                                .tracking(2)
                                .foregroundStyle(AppTheme.green)
                            Text("All users have been notified.")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .padding(.bottom, 24)

                        Button { dismiss() } label: {
                            Text("Done")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppTheme.cardBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Button { confirmSend = true } label: {
                            HStack(spacing: 10) {
                                if isSending {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 16))
                                }
                                Text(isSending ? "SENDING..." : "SEND EMERGENCY ALERT")
                                    .font(.system(size: 16, weight: .black))
                                    .tracking(1)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(selectedType != nil ? AppTheme.red : AppTheme.cardBg3)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(selectedType == nil || isSending)
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .confirmationDialog(
            "Confirm Emergency Alert",
            isPresented: $confirmSend,
            titleVisibility: .visible
        ) {
            Button("Send \(selectedType?.displayName ?? "") Alert", role: .destructive) {
                sendAlert()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will send a critical notification to ALL users in the building. This cannot be undone.")
        }
    }

    // MARK: - Type row

    private func emergencyTypeRow(_ type: EmergencyType) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedType = type }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AppTheme.red.opacity(0.2) : AppTheme.cardBg3)
                        .frame(width: 44, height: 44)
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.red : AppTheme.textSec)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? .white : AppTheme.textPri)
                    Text(type.shortInstruction)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textSec)
                        .lineLimit(1)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.red : AppTheme.textDim, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.red)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(14)
            .background(isSelected ? AppTheme.redDim : AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppTheme.red.opacity(0.4) : AppTheme.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Send

    private func sendAlert() {
        guard let type = selectedType else { return }
        isSending = true

        let alert = EmergencyAlert(
            id: UUID().uuidString,
            type: type,
            message: type.shortInstruction,
            sentBy: auth.userEmail,
            sentByName: auth.userName,
            timestamp: Date(),
            isActive: true
        )

        Task {
            do {
                try await FirestoreService.shared.sendEmergencyAlert(alert)
                viewModel.onEmergencyAlertSent(alert)
                withAnimation { didSend = true }
            } catch {
                print("[SendEmergencyView] Failed: \(error.localizedDescription)")
            }
            isSending = false
        }
    }
}

#Preview {
    SendEmergencyView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
        .environmentObject(AuthViewModel())
}
