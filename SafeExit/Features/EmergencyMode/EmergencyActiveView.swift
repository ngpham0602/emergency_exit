import SwiftUI

struct EmergencyActiveView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var sosHeld       = false
    @State private var sosProgress   = 0.0
    @State private var sosFired      = false

    var body: some View {
        ZStack {
            AppTheme.emergencyBg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Nav bar row
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("EMERGENCY ACTIVE")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "shield.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                    // Alert icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 116, height: 116)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(red: 0.98, green: 0.78, blue: 0.20))
                    }
                    .padding(.bottom, 20)

                    Text("ACTIVE ALERT")
                        .font(.system(size: 30, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Text("Life-threatening hazard detected nearby.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.bottom, 24)

                    // Emergency code card
                    VStack(spacing: 10) {
                        Text("EMERGENCY CODE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(AppTheme.red)

                        Text("100")
                            .font(.system(size: 56, weight: .black))
                            .foregroundStyle(AppTheme.red)

                        Text("CRITICAL")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundStyle(AppTheme.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .overlay(Capsule().stroke(AppTheme.red, lineWidth: 1.5))
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.emergencyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    // Immediate actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IMMEDIATE ACTIONS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 20)

                        immediateAction(icon: "arrow.down.circle",
                            text: "Stay low to the ground to avoid smoke inhalation.")
                        immediateAction(icon: "xmark.circle",
                            text: "Do not use elevators. Use the marked stairwells only.")

                        if let instruction = viewModel.routeResult?.instructions.first {
                            immediateAction(icon: "arrow.up.right.circle",
                                text: instruction.detail)
                        } else {
                            immediateAction(icon: "figure.walk",
                                text: "Follow the green LED floor paths to the nearest exit.")
                        }
                    }
                    .padding(.bottom, 24)

                    // Quick action grid
                    HStack(spacing: 12) {
                        QuickActionButton(icon: "location.fill",  title: "Share\nLocation",   sub: "Live GPS\nTracking")
                        QuickActionButton(icon: "phone.fill",     title: "Call\nSecurity",    sub: "Direct\nResponse")
                        QuickActionButton(icon: "mappin.circle",  title: "Safe Zone",         sub: "0.4mi Nearby")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                    // SOS hold button
                    Text("HOLD FOR 3 SECONDS TO TRIGGER SIREN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, 16)

                    ZStack {
                        Circle()
                            .fill(AppTheme.emergencyCard)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: sosProgress)
                            .stroke(AppTheme.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 3), value: sosProgress)

                        VStack(spacing: 4) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(sosFired ? AppTheme.red : .white)
                            Text("SOS")
                                .font(.system(size: 14, weight: .black))
                                .tracking(2)
                                .foregroundStyle(sosFired ? AppTheme.red : .white)
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 3)
                            .onChanged { _ in
                                withAnimation { sosProgress = 1.0 }
                            }
                            .onEnded { _ in
                                sosFired = true
                            }
                    )
                    .onTapGesture {
                        sosProgress = 0
                        sosFired = false
                    }
                    .padding(.bottom, 20)

                    // False alarm button
                    Button {
                        viewModel.resetHazards()
                        dismiss()
                    } label: {
                        Text("Report False Alarm")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func immediateAction(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 28)
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let sub: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.85))
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(sub)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    EmergencyActiveView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
