import SwiftUI

// MARK: - Root container (switches between Welcome and Sign In)

struct LandingView: View {
    @State private var showSignIn = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            if showSignIn {
                SignInView(showSignIn: $showSignIn)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)))
            } else {
                WelcomeOnboardingView(showSignIn: $showSignIn)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: showSignIn)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Welcome / Onboarding

struct WelcomeOnboardingView: View {
    @Binding var showSignIn: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 52)

            // Logo mark
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 76, height: 76)
                Image(systemName: "shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.bg)
            }

            Spacer().frame(height: 12)

            Text("SAFEEXIT")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(6)
                .foregroundStyle(AppTheme.green)

            // Green underline accent
            Rectangle()
                .fill(AppTheme.green)
                .frame(width: 40, height: 2)
                .padding(.top, 6)

            Spacer().frame(height: 28)

            // Radar + building graphic
            RadarBuildingGraphic()
                .frame(width: 300, height: 260)

            Spacer().frame(height: 24)

            // Headline
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Safety,")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.textPri)
                Text("Optimized.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer().frame(height: 10)

            Text("Instant, AI-recalculated evacuation paths\nthat adapt to real-time building hazards.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSec)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer().frame(height: 20)

            // Feature chips
            HStack(spacing: 8) {
                LandingChip(icon: "mappin.circle.fill", label: "LIVE MAP")
                LandingChip(icon: "bolt.fill",          label: "FAST EXIT")
                LandingChip(icon: "shield.fill",        label: "SOS SYNC")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

            // CTA
            Button { showSignIn = true } label: {
                HStack {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppTheme.bg)
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(AppTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)

            Button { showSignIn = true } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(AppTheme.textSec)
                    Text("Sign In")
                        .foregroundStyle(AppTheme.green)
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
            }
            .padding(.bottom, 44)
        }
    }
}

// MARK: - Sign In

struct SignInView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Binding var showSignIn: Bool

    @State private var email    = ""
    @State private var password = ""
    @State private var showPwd  = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                Image(systemName: "shield.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(AppTheme.bg)
            }

            Spacer().frame(height: 12)

            Text("SAFEEXIT")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(6)
                .foregroundStyle(AppTheme.textPri)

            Spacer().frame(height: 44)

            // Fields
            VStack(spacing: 18) {
                // Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("OPERATIONAL EMAIL")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.textSec)

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(AppTheme.textDim)
                            .frame(width: 18)
                        TextField("name@agency.gov", text: $email)
                            .foregroundStyle(AppTheme.textPri)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .email)
                    }
                    .padding(16)
                    .background(AppTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focus == .email ? AppTheme.green.opacity(0.45) : AppTheme.border,
                                    lineWidth: 1)
                    )
                }

                // Password
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ACCESS KEY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text("Forgot Password?")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.textDim)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(AppTheme.textDim)
                            .frame(width: 18)
                        Group {
                            if showPwd {
                                TextField("", text: $password)
                            } else {
                                SecureField("••••••••", text: $password)
                            }
                        }
                        .foregroundStyle(AppTheme.textPri)
                        .focused($focus, equals: .password)

                        Button { showPwd.toggle() } label: {
                            Image(systemName: showPwd ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(AppTheme.textDim)
                        }
                    }
                    .padding(16)
                    .background(AppTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focus == .password ? AppTheme.green.opacity(0.45) : AppTheme.border,
                                    lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 28)

            // Error
            if let err = auth.signInError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(AppTheme.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 28)
            }

            Spacer()

            // Submit
            Button { auth.signIn(email: email, password: password) } label: {
                HStack {
                    Text("INITIALIZE SESSION")
                        .font(.system(size: 15, weight: .black))
                        .tracking(1)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppTheme.bg)
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(AppTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)

            Button { showSignIn = false } label: {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(AppTheme.textSec)
                    Text("Sign Up")
                        .foregroundStyle(AppTheme.green)
                        .fontWeight(.semibold)
                }
                .font(.system(size: 14))
            }
            .padding(.bottom, 16)

            HStack(spacing: 24) {
                Text("VER 2.4.0-SAFE")
                Text("SECURE_TUNNEL: ON")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(AppTheme.textDim)
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Shared landing components

private struct LandingChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(0.5)
        }
        .foregroundStyle(AppTheme.textSec)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(AppTheme.cardBg)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
    }
}

// MARK: - Radar + Building graphic

private struct RadarBuildingGraphic: View {
    var body: some View {
        ZStack {
            // Concentric radar rings
            ForEach([1.0, 0.78, 0.58, 0.38], id: \.self) { scale in
                Circle()
                    .stroke(AppTheme.green.opacity(scale * 0.13), lineWidth: 1)
                    .frame(width: 260, height: 260)
                    .scaleEffect(scale)
            }

            // Subtle green glow behind building
            Circle()
                .fill(AppTheme.green.opacity(0.04))
                .frame(width: 160, height: 160)

            // Isometric building canvas
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let cx = w * 0.5, cy = h * 0.52

                let isoW: CGFloat = 88, isoH: CGFloat = 60, depth: CGFloat = 32

                // Top face
                let top = Path { p in
                    p.move(to:    CGPoint(x: cx,         y: cy - isoH * 0.5))
                    p.addLine(to: CGPoint(x: cx + isoW,  y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx,         y: cy - isoH * 0.5 + depth * 0.8))
                    p.addLine(to: CGPoint(x: cx - isoW,  y: cy - isoH * 0.5 + depth * 0.4))
                    p.closeSubpath()
                }
                ctx.fill(top, with: .color(Color(white: 0.20)))

                // Right face
                let right = Path { p in
                    p.move(to:    CGPoint(x: cx + isoW, y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx + isoW, y: cy + isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx,         y: cy + isoH * 0.5 + depth * 0.8))
                    p.addLine(to: CGPoint(x: cx,         y: cy - isoH * 0.5 + depth * 0.8))
                    p.closeSubpath()
                }
                ctx.fill(right, with: .color(Color(white: 0.10)))

                // Left face
                let left = Path { p in
                    p.move(to:    CGPoint(x: cx - isoW, y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx - isoW, y: cy + isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx,         y: cy + isoH * 0.5 + depth * 0.8))
                    p.addLine(to: CGPoint(x: cx,         y: cy - isoH * 0.5 + depth * 0.8))
                    p.closeSubpath()
                }
                ctx.fill(left, with: .color(Color(white: 0.14)))

                // Interior room dividers on top face (floor plan look)
                let roomLineColor = Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.25)
                let roomStyle = StrokeStyle(lineWidth: 0.6)
                // Horizontal divider across top face
                let hDiv = Path { p in
                    p.move(to:    CGPoint(x: cx - isoW * 0.2, y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx + isoW * 0.8, y: cy - isoH * 0.5 + depth * 0.4 - 8))
                }
                ctx.stroke(hDiv, with: .color(roomLineColor), style: roomStyle)
                // Vertical divider
                let vDiv = Path { p in
                    p.move(to:    CGPoint(x: cx + isoW * 0.1, y: cy - isoH * 0.5))
                    p.addLine(to: CGPoint(x: cx + isoW * 0.1, y: cy - isoH * 0.5 + depth * 0.8))
                }
                ctx.stroke(vDiv, with: .color(roomLineColor), style: roomStyle)

                // Windows on right face
                let greenColor = Color(red: 0.22, green: 0.96, blue: 0.29)
                for row in 0..<3 {
                    for col in 0..<2 {
                        let wx = cx + 14 + CGFloat(col) * 28
                        let wy = cy - 8 + CGFloat(row) * 20
                        let winRect = CGRect(x: wx, y: wy, width: 11, height: 13)
                        ctx.fill(Path(winRect),
                                 with: .color(greenColor.opacity(col == 0 && row == 1 ? 0.85 : 0.25)))
                    }
                }

                // Windows on left face
                for row in 0..<3 {
                    let wx = cx - 36
                    let wy = cy - 8 + CGFloat(row) * 20
                    ctx.fill(Path(CGRect(x: wx, y: wy, width: 10, height: 13)),
                             with: .color(Color(white: 0.25)))
                }

                // Blue wireframe edges
                let edgeColor = Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.40)
                let edgeStyle = StrokeStyle(lineWidth: 0.9)
                ctx.stroke(top,   with: .color(edgeColor), style: edgeStyle)
                ctx.stroke(right, with: .color(edgeColor), style: edgeStyle)
                ctx.stroke(left,  with: .color(edgeColor), style: edgeStyle)
            }
            .frame(width: 220, height: 160)

            // Floating icon cards
            // Map pin — top right, green card
            FloatingIconCard(icon: "mappin.and.ellipse", isGreen: true)
                .offset(x: 104, y: -88)

            // Bolt — right middle, dark card
            FloatingIconCard(icon: "bolt.fill", isGreen: false)
                .offset(x: 114, y: 14)

            // Shield — bottom left, dark card
            FloatingIconCard(icon: "shield.fill", isGreen: false)
                .offset(x: -104, y: 70)
        }
    }
}

// MARK: - Floating icon card

private struct FloatingIconCard: View {
    let icon: String
    let isGreen: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isGreen ? AppTheme.green : AppTheme.cardBg2)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isGreen ? Color.clear : AppTheme.border, lineWidth: 1)
                )
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isGreen ? AppTheme.bg : AppTheme.textSec)
        }
    }
}

#Preview("Landing") {
    LandingView()
        .environmentObject(AuthViewModel())
}
