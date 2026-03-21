import SwiftUI

struct EmployeeEmergencyAlertView: View {
    let alert: EmergencyAlert
    let onOpenMap: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Full-screen red gradient
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.12, blue: 0.12),
                    Color(red: 0.35, green: 0.06, blue: 0.06),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Top bar
                    HStack {
                        // Close button
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppTheme.red)
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                    value: pulseScale
                                )
                            Text("LIVE")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(AppTheme.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Pulsing alert icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.red.opacity(0.15))
                            .frame(width: 130, height: 130)
                            .scaleEffect(pulseScale)
                        Circle()
                            .fill(AppTheme.red.opacity(0.10))
                            .frame(width: 100, height: 100)
                        Image(systemName: alert.type.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 24)

                    // Type badge
                    Text(alert.type.notificationTitle)
                        .font(.system(size: 28, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .padding(.bottom, 8)

                    Text(alert.displayTimestamp)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 24)

                    // Instruction card
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(red: 0.98, green: 0.78, blue: 0.20))

                        Text(alert.type.shortInstruction)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Sent by \(alert.sentByName)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                    // Go to Map button — primary action
                    Button {
                        onOpenMap()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 18))
                            Text("FIND NEAREST EXIT")
                                .font(.system(size: 17, weight: .black))
                                .tracking(1)
                        }
                        .foregroundStyle(AppTheme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(AppTheme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                    // Secondary actions
                    HStack(spacing: 12) {
                        Button {
                            // Placeholder — call security
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                Text("Call Security")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button {
                            // Placeholder — share location
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18))
                                Text("Share Location")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { pulseScale = 1.15 }
    }
}

#Preview {
    EmployeeEmergencyAlertView(
        alert: EmergencyAlert(
            id: "preview",
            type: .fire,
            message: "Evacuate now. Find the nearest exit immediately.",
            sentBy: "test@example.com",
            sentByName: "John Smith",
            timestamp: Date(),
            isActive: true
        ),
        onOpenMap: {}
    )
}
