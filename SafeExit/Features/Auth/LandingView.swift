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
            Spacer()

            // Logo mark
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .frame(width: 92, height: 92)
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.bg)
            }

            Spacer().frame(height: 16)

            Text("SAFEEXIT")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(6)
                .foregroundStyle(AppTheme.green)

            Spacer().frame(height: 36)

            // Isometric building graphic
            BuildingGraphic()
                .frame(width: 220, height: 150)

            Spacer().frame(height: 32)

            // Headline
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Safety,")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.textPri)
                Text("Optimized.")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer().frame(height: 10)

            Text("Instant, recalculated evacuation paths\nthat adapt to real-time building hazards.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSec)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer().frame(height: 24)

            // Feature chips
            HStack(spacing: 8) {
                LandingChip(icon: "map.fill",         label: "LIVE MAP")
                LandingChip(icon: "bolt.fill",        label: "FAST EXIT")
                LandingChip(icon: "dot.radiowaves.up.forward", label: "SOS SYNC")
            }
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
            // Hien
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

// MARK: - Isometric building illustration

private struct BuildingGraphic: View {
    var body: some View {
        ZStack {
            // Outer glow rings
            Circle()
                .stroke(AppTheme.green.opacity(0.06), lineWidth: 50)
                .frame(width: 120)
            Circle()
                .stroke(AppTheme.green.opacity(0.04), lineWidth: 30)
                .frame(width: 170)

            Canvas { ctx, size in
                let w = size.width, h = size.height
                let cx = w * 0.5, cy = h * 0.52

                // -- Isometric building --
                let isoW: CGFloat = 80, isoH: CGFloat = 55, depth: CGFloat = 30

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

                // Windows on right face
                let greenColor = Color(red: 0.22, green: 0.96, blue: 0.29)
                for row in 0..<3 {
                    for col in 0..<2 {
                        let wx = cx + 14 + CGFloat(col) * 26
                        let wy = cy - 10 + CGFloat(row) * 20
                        let winRect = CGRect(x: wx, y: wy, width: 10, height: 13)
                        ctx.fill(Path(winRect), with: .color(greenColor.opacity(col == 0 && row == 1 ? 0.9 : 0.3)))
                    }
                }

                // Windows on left face
                for row in 0..<3 {
                    let wx = cx - 36
                    let wy = cy - 10 + CGFloat(row) * 20
                    ctx.fill(Path(CGRect(x: wx, y: wy, width: 10, height: 13)),
                             with: .color(Color(white: 0.25)))
                }

                // Wireframe edges (blue-ish tint like screenshot)
                let edgeColor = Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.35)
                let style = StrokeStyle(lineWidth: 0.8)
                ctx.stroke(top, with: .color(edgeColor), style: style)
                ctx.stroke(right, with: .color(edgeColor), style: style)
                ctx.stroke(left, with: .color(edgeColor), style: style)
            }

            // Floating icons
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.green)
                .offset(x: 72, y: -40)

            Image(systemName: "shield.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textDim)
                .offset(x: -72, y: 22)

            Image(systemName: "bolt.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textDim)
                .offset(x: 74, y: 18)
        }
    }
}

#Preview("Landing") {
    LandingView()
        .environmentObject(AuthViewModel())
}
