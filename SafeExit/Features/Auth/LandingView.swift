import SwiftUI

// MARK: - Auth flow state

fileprivate enum AuthFlow {
    case welcome
    case signIn
    case rolePicker
    case register(UserRole)
}

// MARK: - Root container

struct LandingView: View {
    @State private var flow: AuthFlow = .welcome

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            switch flow {
            case .welcome:
                WelcomeOnboardingView(flow: $flow)
                    .transition(.asymmetric(insertion: .move(edge: .leading),
                                            removal:   .move(edge: .leading)))
            case .signIn:
                SignInView(flow: $flow)
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal:   .move(edge: .trailing)))
            case .rolePicker:
                RolePickerView(flow: $flow)
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal:   .move(edge: .trailing)))
            case .register(let role):
                RegisterView(role: role, flow: $flow)
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal:   .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.28), value: flowID)
        .preferredColorScheme(.dark)
    }

    private var flowID: String {
        switch flow {
        case .welcome:        return "welcome"
        case .signIn:         return "signIn"
        case .rolePicker:     return "rolePicker"
        case .register(let r): return "register-\(r.rawValue)"
        }
    }
}

// MARK: - Welcome / Onboarding

fileprivate struct WelcomeOnboardingView: View {
    @Binding var flow: AuthFlow

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

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

            BuildingGraphic()
                .frame(width: 220, height: 150)

            Spacer().frame(height: 32)

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

            HStack(spacing: 8) {
                LandingChip(icon: "map.fill",                    label: "LIVE MAP")
                LandingChip(icon: "bolt.fill",                   label: "FAST EXIT")
                LandingChip(icon: "dot.radiowaves.up.forward",   label: "SOS SYNC")
            }
            .padding(.horizontal, 28)

            Spacer()

            Button { flow = .rolePicker } label: {
                HStack {
                    Text("Create Account")
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

            Button { flow = .signIn } label: {
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

// MARK: - Role Picker

fileprivate struct RolePickerView: View {
    @Binding var flow: AuthFlow

    var body: some View {
        VStack(spacing: 0) {
            // Back
            HStack {
                Button { flow = .welcome } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 56)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("I AM JOINING AS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
                Text("Choose your role")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(AppTheme.textPri)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer().frame(height: 32)

            // Role cards
            VStack(spacing: 14) {
                RoleCard(
                    role: .security,
                    title: "Security Officer",
                    subtitle: "Manage hazards, control evacuations\nand monitor all building activity.",
                    accentColor: AppTheme.amber,
                    icon: "shield.checkered"
                ) {
                    flow = .register(.security)
                }

                RoleCard(
                    role: .employee,
                    title: "Employee",
                    subtitle: "Get real-time evacuation guidance\nand report hazards as you see them.",
                    accentColor: AppTheme.green,
                    icon: "person.fill"
                ) {
                    flow = .register(.employee)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button { flow = .signIn } label: {
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

private struct RoleCard: View {
    let role: UserRole
    let title: String
    let subtitle: String
    let accentColor: Color
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.textPri)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textDim)
            }
            .padding(18)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.25), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Register

fileprivate struct RegisterView: View {
    let role: UserRole
    @Binding var flow: AuthFlow
    @EnvironmentObject private var auth: AuthViewModel

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var showPwd  = false
    @FocusState private var focus: Field?

    private enum Field { case name, email, password, confirm }

    private var accentColor: Color {
        role == .security ? AppTheme.amber : AppTheme.green
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Back
                HStack {
                    Button { flow = .rolePicker } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textSec)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 28)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 38, height: 38)
                            Image(systemName: role.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                        Text(role.displayName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(accentColor)
                    }
                    Text("Create your account")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(AppTheme.textPri)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.bottom, 32)

                // Fields
                VStack(spacing: 16) {
                    AuthField(label: "FULL NAME", icon: "person.fill",
                              placeholder: "John Smith", text: $name,
                              focus: $focus, field: .name,
                              accentColor: accentColor)

                    AuthField(label: "EMAIL", icon: "envelope.fill",
                              placeholder: "you@company.com", text: $email,
                              focus: $focus, field: .email,
                              keyboard: .emailAddress, accentColor: accentColor)

                    AuthField(label: "PASSWORD", icon: "lock.fill",
                              placeholder: "Min. 6 characters", text: $password,
                              focus: $focus, field: .password,
                              isSecure: !showPwd, showToggle: true,
                              showPwd: $showPwd, accentColor: accentColor)

                    AuthField(label: "CONFIRM PASSWORD", icon: "lock.fill",
                              placeholder: "Repeat password", text: $confirm,
                              focus: $focus, field: .confirm,
                              isSecure: !showPwd, accentColor: accentColor)
                }
                .padding(.horizontal, 28)

                // Error
                if let err = auth.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                        Text(err)
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(AppTheme.red)
                    .padding(14)
                    .background(AppTheme.redDim)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                }

                // Validation hint
                if !password.isEmpty && !confirm.isEmpty && password != confirm {
                    Text("Passwords do not match.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                }

                Spacer().frame(height: 32)

                // Submit
                Button {
                    guard password == confirm else {
                        auth.errorMessage = "Passwords do not match."
                        return
                    }
                    auth.register(name: name, email: email, password: password, role: role)
                } label: {
                    HStack {
                        if auth.isLoading {
                            ProgressView()
                                .tint(AppTheme.bg)
                        } else {
                            Text("CREATE ACCOUNT")
                                .font(.system(size: 15, weight: .black))
                                .tracking(1)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .foregroundStyle(AppTheme.bg)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 18)
                    .background(auth.isLoading ? accentColor.opacity(0.5) : accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(auth.isLoading)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

                Button { flow = .signIn } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(AppTheme.textSec)
                        Text("Sign In")
                            .foregroundStyle(accentColor)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                }
                .padding(.bottom, 44)
            }
        }
    }
}

// MARK: - Sign In

fileprivate struct SignInView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Binding var flow: AuthFlow

    @State private var email    = ""
    @State private var password = ""
    @State private var showPwd  = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

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

            VStack(spacing: 18) {
                AuthField(label: "EMAIL", icon: "envelope.fill",
                          placeholder: "you@company.com", text: $email,
                          focus: $focus, field: .email,
                          keyboard: .emailAddress, accentColor: AppTheme.green)

                AuthField(label: "ACCESS KEY", icon: "lock.fill",
                          placeholder: "••••••••", text: $password,
                          focus: $focus, field: .password,
                          isSecure: !showPwd, showToggle: true,
                          showPwd: $showPwd, accentColor: AppTheme.green,
                          trailingLabel: "Forgot Password?")
            }
            .padding(.horizontal, 28)

            if let err = auth.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                    Text(err)
                        .font(.system(size: 13))
                }
                .foregroundStyle(AppTheme.red)
                .padding(14)
                .background(AppTheme.redDim)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 28)
                .padding(.top, 16)
            }

            Spacer()

            Button { auth.signIn(email: email, password: password) } label: {
                HStack {
                    if auth.isLoading {
                        ProgressView().tint(AppTheme.bg)
                    } else {
                        Text("SIGN IN")
                            .font(.system(size: 15, weight: .black))
                            .tracking(1)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundStyle(AppTheme.bg)
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(auth.isLoading ? AppTheme.green.opacity(0.5) : AppTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(auth.isLoading)
            .padding(.horizontal, 28)
            .padding(.bottom, 20)

            Button { flow = .rolePicker } label: {
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

// MARK: - Reusable auth field

private struct AuthField<F: Hashable>: View {
    let label: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<F?>.Binding
    let field: F
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var showToggle: Bool = false
    @Binding var showPwd: Bool
    let accentColor: Color
    var trailingLabel: String? = nil

    init(label: String, icon: String, placeholder: String,
         text: Binding<String>, focus: FocusState<F?>.Binding, field: F,
         keyboard: UIKeyboardType = .default, isSecure: Bool = false,
         showToggle: Bool = false, showPwd: Binding<Bool> = .constant(false),
         accentColor: Color, trailingLabel: String? = nil) {
        self.label = label
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.focus = focus
        self.field = field
        self.keyboard = keyboard
        self.isSecure = isSecure
        self.showToggle = showToggle
        self._showPwd = showPwd
        self.accentColor = accentColor
        self.trailingLabel = trailingLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
                if let trailing = trailingLabel {
                    Spacer()
                    Text(trailing)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textDim)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.textDim)
                    .frame(width: 18)

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboard)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                }
                .foregroundStyle(AppTheme.textPri)
                .focused(focus, equals: field)

                if showToggle {
                    Button { showPwd.toggle() } label: {
                        Image(systemName: showPwd ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(AppTheme.textDim)
                    }
                }
            }
            .padding(16)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focus.wrappedValue == field
                            ? accentColor.opacity(0.45) : AppTheme.border, lineWidth: 1)
            )
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
            Circle().stroke(AppTheme.green.opacity(0.06), lineWidth: 50).frame(width: 120)
            Circle().stroke(AppTheme.green.opacity(0.04), lineWidth: 30).frame(width: 170)

            Canvas { ctx, size in
                let w = size.width, h = size.height
                let cx = w * 0.5, cy = h * 0.52
                let isoW: CGFloat = 80, isoH: CGFloat = 55, depth: CGFloat = 30

                let top = Path { p in
                    p.move(to:    CGPoint(x: cx,        y: cy - isoH * 0.5))
                    p.addLine(to: CGPoint(x: cx + isoW, y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx,        y: cy - isoH * 0.5 + depth * 0.8))
                    p.addLine(to: CGPoint(x: cx - isoW, y: cy - isoH * 0.5 + depth * 0.4))
                    p.closeSubpath()
                }
                ctx.fill(top, with: .color(Color(white: 0.20)))

                let right = Path { p in
                    p.move(to:    CGPoint(x: cx + isoW, y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx + isoW, y: cy + isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx,        y: cy + isoH * 0.5 + depth * 0.8))
                    p.addLine(to: CGPoint(x: cx,        y: cy - isoH * 0.5 + depth * 0.8))
                    p.closeSubpath()
                }
                ctx.fill(right, with: .color(Color(white: 0.10)))

                let left = Path { p in
                    p.move(to:    CGPoint(x: cx - isoW, y: cy - isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx - isoW, y: cy + isoH * 0.5 + depth * 0.4))
                    p.addLine(to: CGPoint(x: cx,        y: cy + isoH * 0.5 + depth * 0.8))
                    p.addLine(to: CGPoint(x: cx,        y: cy - isoH * 0.5 + depth * 0.8))
                    p.closeSubpath()
                }
                ctx.fill(left, with: .color(Color(white: 0.14)))

                let green = Color(red: 0.22, green: 0.96, blue: 0.29)
                for row in 0..<3 {
                    for col in 0..<2 {
                        let wx = cx + 14 + CGFloat(col) * 26
                        let wy = cy - 10 + CGFloat(row) * 20
                        ctx.fill(Path(CGRect(x: wx, y: wy, width: 10, height: 13)),
                                 with: .color(green.opacity(col == 0 && row == 1 ? 0.9 : 0.3)))
                    }
                }
                for row in 0..<3 {
                    ctx.fill(Path(CGRect(x: cx - 36, y: cy - 10 + CGFloat(row) * 20, width: 10, height: 13)),
                             with: .color(Color(white: 0.25)))
                }

                let edge = Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.35)
                let style = StrokeStyle(lineWidth: 0.8)
                ctx.stroke(top, with: .color(edge), style: style)
                ctx.stroke(right, with: .color(edge), style: style)
                ctx.stroke(left, with: .color(edge), style: style)
            }

            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20)).foregroundStyle(AppTheme.green).offset(x: 72, y: -40)
            Image(systemName: "shield.fill")
                .font(.system(size: 16)).foregroundStyle(AppTheme.textDim).offset(x: -72, y: 22)
            Image(systemName: "bolt.fill")
                .font(.system(size: 16)).foregroundStyle(AppTheme.textDim).offset(x: 74, y: 18)
        }
    }
}

#Preview("Landing") {
    LandingView().environmentObject(AuthViewModel())
}
