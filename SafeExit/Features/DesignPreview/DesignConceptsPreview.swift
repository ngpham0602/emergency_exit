// DesignConceptsPreview.swift
// Standalone design showcase — not connected to AppViewModel.
// To preview: temporarily set this as the root in SafeExitApp.swift,
// or use the Xcode #Preview macros below each view.

import SwiftUI

// MARK: - Preview Entry Point

struct DesignConceptsPreview: View {
    @State private var selectedConcept = 0
    private let concepts = ["Signal Red", "Dark Shield", "Breathing Room", "Grid Map", "Soft Emergency"]

    var body: some View {
        VStack(spacing: 0) {
            // Concept picker strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<concepts.count, id: \.self) { i in
                        Button(concepts[i]) {
                            withAnimation(.easeInOut(duration: 0.25)) { selectedConcept = i }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedConcept == i ? Color.primary : Color.clear)
                        .foregroundStyle(selectedConcept == i ? Color(uiColor: .systemBackground) : .primary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.primary, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(uiColor: .secondarySystemBackground))

            // Concept screens
            TabView(selection: $selectedConcept) {
                Concept1_SignalRed().tag(0)
                Concept2_DarkShield().tag(1)
                Concept3_BreathingRoom().tag(2)
                Concept4_GridMap().tag(3)
                Concept5_SoftEmergency().tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Concept 1: Signal Red

struct Concept1_SignalRed: View {
    @State private var screen: Screen = .landing
    @State private var email = ""
    @State private var password = ""

    enum Screen { case landing, login, welcome }

    let red = Color(red: 0.84, green: 0.16, blue: 0.16)

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            switch screen {
            case .landing: landingView
            case .login:   loginView
            case .welcome: welcomeView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
    }

    var landingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(red).frame(width: 10, height: 10)
                Text("SafeExit")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(uiColor: .label))
            }
            .padding(.top, 20)

            Spacer()

            Image(systemName: "arrow.up.right.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 110)
                .foregroundStyle(red)

            Spacer().frame(height: 32)

            Text("Your fastest\npath to safety.")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
                .lineSpacing(2)

            Spacer()

            Button { screen = .login } label: {
                Text("Get Started")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(red)
                    .clipShape(Capsule())
            }

            Button { screen = .login } label: {
                Text("Already a user? Sign in →")
                    .font(.system(size: 14))
                    .foregroundStyle(red)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 28)
    }

    var loginView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { screen = .landing } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(red)
            }
            .padding(.top, 20)

            Spacer().frame(height: 40)

            Text("Welcome\nback.")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))

            Spacer().frame(height: 48)

            VStack(spacing: 28) {
                UnderlineField(label: "Email", text: $email, accentColor: red)
                UnderlineField(label: "Password", text: $password, accentColor: red, isSecure: true)
            }

            Spacer().frame(height: 16)
            HStack {
                Spacer()
                Text("Forgot password?").font(.caption).foregroundStyle(red)
            }

            Spacer()

            Button { screen = .welcome } label: {
                Text("Sign In")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(red)
                    .clipShape(Capsule())
            }

            Button {} label: {
                Label("Sign in with Face ID", systemImage: "faceid")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(red)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 28)
    }

    var welcomeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Good morning,\nAlex.")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))

            Spacer().frame(height: 12)

            Text("Building A · Floor 2")
                .font(.system(size: 16))
                .foregroundStyle(Color(uiColor: .secondaryLabel))

            Spacer().frame(height: 32)

            HStack(spacing: 8) {
                Circle().fill(Color(red: 0.18, green: 0.64, blue: 0.33)).frame(width: 8, height: 8)
                Text("All clear · 0 active hazards")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            Spacer()

            Button { screen = .landing } label: {
                Text("Start Navigation")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(red)
                    .clipShape(Capsule())
            }

            Button { screen = .landing } label: {
                Text("Sign out")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 28)
    }
}

// MARK: - Concept 2: Dark Shield

struct Concept2_DarkShield: View {
    @State private var screen: Screen = .landing
    @State private var email = ""
    @State private var password = ""

    enum Screen { case landing, login, welcome }

    let bg    = Color(red: 0.05, green: 0.05, blue: 0.05)
    let amber = Color(red: 1.0,  green: 0.72, blue: 0.01)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            switch screen {
            case .landing: landingView
            case .login:   loginView
            case .welcome: welcomeView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
    }

    var landingView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hexagon logo mark
            ZStack {
                Image(systemName: "hexagon.fill")
                    .resizable().scaledToFit().frame(width: 90)
                    .foregroundStyle(amber.opacity(0.15))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(amber)
            }

            Spacer().frame(height: 28)

            Text("SAFEEXIT")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .tracking(8)

            Spacer().frame(height: 12)

            Rectangle().fill(amber).frame(height: 1).padding(.horizontal, 60)

            Spacer().frame(height: 12)

            Text("Navigate out. Stay safe.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)

            Spacer()

            VStack(spacing: 14) {
                Button { screen = .login } label: {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(amber)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button { screen = .login } label: {
                    Text("Continue as Guest")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(amber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(amber, lineWidth: 1.5))
                }
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 40)
        }
    }

    var loginView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { screen = .landing } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(amber)
            }
            .padding(.top, 20)
            .padding(.horizontal, 28)

            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text("SIGN IN")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(amber)
                    .tracking(4)
                Text("Access your\nsafe routes.")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 48)

            VStack(spacing: 20) {
                DarkField(label: "Email", text: $email, accentColor: amber)
                DarkField(label: "Password", text: $password, accentColor: amber, isSecure: true)
            }
            .padding(.horizontal, 28)

            Spacer()

            Button { screen = .welcome } label: {
                Text("Sign In")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(amber)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 32)
        }
    }

    var welcomeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("WELCOME BACK")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(amber)
                .tracking(4)
                .padding(.horizontal, 28)

            Spacer().frame(height: 8)

            Text("Alex Chen")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)

            Spacer().frame(height: 24)

            HStack(spacing: 0) {
                StatPill(value: "A", label: "BUILDING", accent: amber, bg: bg)
                StatPill(value: "2F", label: "FLOOR", accent: amber, bg: bg)
                StatPill(value: "0", label: "HAZARDS", accent: amber, bg: bg)
            }
            .padding(.horizontal, 20)

            Spacer()

            Button { screen = .landing } label: {
                HStack {
                    Text("Start Navigation")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(bg)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(amber)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 28)

            Button { screen = .landing } label: {
                Text("Sign out")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            }

            Spacer().frame(height: 40)
        }
    }
}

// MARK: - Concept 3: Breathing Room

struct Concept3_BreathingRoom: View {
    @State private var screen: Screen = .landing
    @State private var email = ""
    @State private var password = ""

    enum Screen { case landing, login, welcome }

    let bg     = Color(red: 0.96, green: 0.96, blue: 0.94)
    let ink    = Color(red: 0.18, green: 0.18, blue: 0.18)
    let coral  = Color(red: 0.88, green: 0.48, blue: 0.37)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            switch screen {
            case .landing: landingView
            case .login:   loginView
            case .welcome: welcomeView
            }
        }
        .animation(.easeInOut(duration: 0.35), value: screen)
    }

    var landingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("SafeExit")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(ink)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundStyle(coral)

            Spacer()

            Text("Know the way\nout, always.")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(ink)
                .lineSpacing(4)

            Spacer()

            Button { screen = .login } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign in")
                        .font(.system(size: 18))
                        .foregroundStyle(coral)
                    Rectangle().fill(coral).frame(height: 1)
                }
            }

            Spacer().frame(height: 60)
        }
        .padding(.horizontal, 36)
    }

    var loginView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { screen = .landing } label: {
                Text("← Back")
                    .font(.system(size: 15))
                    .foregroundStyle(coral)
            }
            .padding(.top, 24)

            Spacer()

            Text("Sign in.")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(ink)

            Spacer().frame(height: 48)

            VStack(spacing: 36) {
                UnderlineField(label: "Email", text: $email, accentColor: coral)
                UnderlineField(label: "Password", text: $password, accentColor: coral, isSecure: true)
            }

            Spacer()

            Button { screen = .welcome } label: {
                HStack {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(coral)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(coral)
                }
            }

            Spacer().frame(height: 60)
        }
        .padding(.horizontal, 36)
    }

    var welcomeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Hello,\nAlex.")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(ink)

            Spacer().frame(height: 20)

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.18, green: 0.64, blue: 0.33))
                    .frame(width: 7, height: 7)
                Text("Building safe · 0 active hazards")
                    .font(.system(size: 13))
                    .foregroundStyle(ink.opacity(0.5))
            }

            Spacer()

            Button { screen = .landing } label: {
                Text("Start Navigation →")
                    .font(.system(size: 18))
                    .foregroundStyle(coral)
            }

            Spacer().frame(height: 12)

            Button { screen = .landing } label: {
                Text("Sign out")
                    .font(.system(size: 13))
                    .foregroundStyle(ink.opacity(0.3))
            }

            Spacer().frame(height: 60)
        }
        .padding(.horizontal, 36)
    }
}

// MARK: - Concept 4: Grid Map

struct Concept4_GridMap: View {
    @State private var screen: Screen = .landing
    @State private var email = ""
    @State private var password = ""

    enum Screen { case landing, login, welcome }

    let blue = Color(red: 0.0, green: 0.47, blue: 1.0)
    let ink  = Color(red: 0.08, green: 0.08, blue: 0.08)

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            DotGridBackground().ignoresSafeArea()
            switch screen {
            case .landing: landingView
            case .login:   loginView
            case .welcome: welcomeView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
    }

    var landingView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mini floorplan graphic
            MiniFloorplanView(accentColor: blue)
                .frame(width: 220, height: 160)
                .padding(.bottom, 32)

            Text("SafeExit")
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundStyle(ink)

            Spacer().frame(height: 8)

            Text("Know your way out.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ink.opacity(0.45))
                .tracking(0.5)

            Spacer()

            Button { screen = .login } label: {
                HStack {
                    Spacer()
                    Text("Get Started")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 18)
                .background(blue)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 40)
        }
    }

    var loginView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { screen = .landing } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(blue)
            }
            .padding(.top, 20)
            .padding(.horizontal, 28)

            Spacer()

            VStack(alignment: .leading, spacing: 32) {
                Text("Sign in\nto SafeExit")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(ink)

                VStack(spacing: 16) {
                    GridTextField(label: "Email", text: $email, accentColor: blue)
                    GridTextField(label: "Password", text: $password, accentColor: blue, isSecure: true)
                }

                Button { screen = .welcome } label: {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 60)
        }
    }

    var welcomeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome back,\nAlex.")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(ink)

                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(blue)
                    Text("Building A · Floor 2")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ink.opacity(0.5))
                }

                MiniRouteStepsView(accentColor: blue)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 28)

            Spacer()

            Button { screen = .landing } label: {
                Text("Begin Evacuation Route")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 28)

            Button { screen = .landing } label: {
                Text("Sign out")
                    .font(.system(size: 13))
                    .foregroundStyle(ink.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }

            Spacer().frame(height: 40)
        }
    }
}

// MARK: - Concept 5: Soft Emergency

struct Concept5_SoftEmergency: View {
    @State private var screen: Screen = .landing
    @State private var email = ""
    @State private var password = ""
    @State private var emergencyActive = false

    enum Screen { case landing, login, welcome }

    let bg      = Color(red: 0.92, green: 0.92, blue: 0.92)
    let ink     = Color(red: 0.18, green: 0.18, blue: 0.18)
    let green   = Color(red: 0.18, green: 0.42, blue: 0.31)
    let red     = Color(red: 0.84, green: 0.16, blue: 0.16)

    var accent: Color { emergencyActive ? red : green }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            switch screen {
            case .landing: landingView
            case .login:   loginView
            case .welcome: welcomeView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
        .animation(.easeInOut(duration: 0.4), value: emergencyActive)
    }

    var landingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SafeExit")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ink)
                Spacer()
                Image(systemName: "shield.fill")
                    .foregroundStyle(green)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)

            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 64))
                    .foregroundStyle(green)

                Text("Emergency\nNavigation")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(ink)

                Text("Fast, clear routes out of\nany building, any situation.")
                    .font(.system(size: 15))
                    .foregroundStyle(ink.opacity(0.5))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 12) {
                Button { screen = .login } label: {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { screen = .login } label: {
                    Text("Create Account")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 40)
        }
    }

    var loginView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { screen = .landing } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(green)
            }
            .padding(.top, 20)
            .padding(.horizontal, 28)

            Spacer()

            VStack(alignment: .leading, spacing: 32) {
                Text("Sign in.")
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(ink)
                    .padding(.horizontal, 28)

                VStack(spacing: 14) {
                    SoftField(label: "Email", text: $email, accentColor: green)
                    SoftField(label: "Password", text: $password, accentColor: green, isSecure: true)
                }
                .padding(.horizontal, 28)

                Button { screen = .welcome } label: {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 28)
            }

            Spacer().frame(height: 60)
        }
    }

    var welcomeView: some View {
        VStack(spacing: 0) {
            // Dynamic top banner
            if emergencyActive {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("EMERGENCY ACTIVE")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(red)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if emergencyActive {
                // Emergency state
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    Text("EVACUATE\nNOW")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(red)
                        .lineSpacing(2)

                    VStack(alignment: .leading, spacing: 14) {
                        RouteStep(icon: "arrow.up", step: "Head to Stairwell B", color: red)
                        RouteStep(icon: "arrow.right", step: "Turn right at Room 210", color: red)
                        RouteStep(icon: "arrow.down.to.line", step: "Exit on ground floor", color: red)
                    }

                    HStack(spacing: 6) {
                        Circle().fill(red).frame(width: 8, height: 8)
                        Text("3 steps · ~45 sec to exit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ink.opacity(0.6))
                    }

                    Spacer()
                }
                .padding(.horizontal, 28)
                .transition(.opacity)
            } else {
                // Normal state
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    Text("Good morning,\nAlex.")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(ink)

                    Spacer().frame(height: 16)

                    HStack(spacing: 8) {
                        Circle().fill(green).frame(width: 8, height: 8)
                        Text("All Clear · 0 active hazards")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(ink.opacity(0.5))
                    }

                    Spacer().frame(height: 32)

                    HStack(spacing: 12) {
                        InfoCard(title: "Building", value: "A", color: green)
                        InfoCard(title: "Floor", value: "2", color: green)
                        InfoCard(title: "Exit", value: "48m", color: green)
                    }

                    Spacer()
                }
                .padding(.horizontal, 28)
                .transition(.opacity)
            }

            Spacer().frame(height: 12)

            VStack(spacing: 10) {
                Button {
                    withAnimation { emergencyActive.toggle() }
                } label: {
                    Text(emergencyActive ? "← Back to Normal View" : "Simulate Emergency")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(emergencyActive ? red : green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { screen = .landing } label: {
                    Text("Sign out")
                        .font(.system(size: 13))
                        .foregroundStyle(ink.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 32)
        }
    }
}

// MARK: - Shared Sub-components

struct UnderlineField: View {
    let label: String
    @Binding var text: String
    let accentColor: Color
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
            if isSecure {
                SecureField("", text: $text)
                    .textContentType(.password)
            } else {
                TextField("", text: $text)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            Rectangle().fill(accentColor.opacity(0.4)).frame(height: 1)
        }
    }
}

struct DarkField: View {
    let label: String
    @Binding var text: String
    let accentColor: Color
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor.opacity(0.7))
                .tracking(2)
            if isSecure {
                SecureField("", text: $text)
                    .foregroundStyle(.white)
            } else {
                TextField("", text: $text)
                    .foregroundStyle(.white)
                    .autocapitalization(.none)
            }
            Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
        }
    }
}

struct GridTextField: View {
    let label: String
    @Binding var text: String
    let accentColor: Color
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
            if isSecure {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
                    .autocapitalization(.none)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentColor.opacity(0.25), lineWidth: 1))
    }
}

struct SoftField: View {
    let label: String
    @Binding var text: String
    let accentColor: Color
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
            if isSecure {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
                    .autocapitalization(.none)
            }
        }
        .padding(16)
        .background(.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let accent: Color
    let bg: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(accent)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(4)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color.opacity(0.7))
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(color)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RouteStep: View {
    let icon: String
    let step: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .clipShape(Circle())
            Text(step)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.18))
        }
    }
}

struct DotGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 22
            let dotSize: CGFloat = 1.5
            var x: CGFloat = spacing
            while x < size.width {
                var y: CGFloat = spacing
                while y < size.height {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                        with: .color(Color(red: 0.0, green: 0.47, blue: 1.0).opacity(0.15))
                    )
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

struct MiniFloorplanView: View {
    let accentColor: Color

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let lineStyle = StrokeStyle(lineWidth: 1.5, lineCap: .round)
            let roomStyle = StrokeStyle(lineWidth: 1.0, lineCap: .round)
            let color = accentColor.opacity(0.6)
            let faint = accentColor.opacity(0.2)

            // Outer building
            var outer = Path()
            outer.addRect(CGRect(x: 10, y: 10, width: w - 20, height: h - 20))
            context.stroke(outer, with: .color(color), style: lineStyle)

            // Corridor line
            var corridor = Path()
            corridor.move(to: CGPoint(x: 10, y: h * 0.5))
            corridor.addLine(to: CGPoint(x: w - 10, y: h * 0.5))
            context.stroke(corridor, with: .color(faint), style: roomStyle)

            // Rooms top row
            for i in 0..<3 {
                var room = Path()
                let rx = 10 + CGFloat(i) * (w - 20) / 3
                room.addRect(CGRect(x: rx, y: 10, width: (w - 20) / 3, height: h * 0.4))
                context.stroke(room, with: .color(faint), style: roomStyle)
            }

            // YOU dot
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.3 - 6, y: h * 0.62, width: 12, height: 12)),
                with: .color(accentColor)
            )

            // Arrow route
            var route = Path()
            route.move(to: CGPoint(x: w * 0.3, y: h * 0.68))
            route.addLine(to: CGPoint(x: w - 20, y: h * 0.68))
            context.stroke(route, with: .color(accentColor.opacity(0.8)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))

            // Exit marker
            context.fill(
                Path(ellipseIn: CGRect(x: w - 26, y: h * 0.68 - 6, width: 12, height: 12)),
                with: .color(accentColor)
            )
        }
    }
}

struct MiniRouteStepsView: View {
    let accentColor: Color
    private let steps = ["Head to Stairwell B", "Turn right at Room 210", "Exit on ground floor"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(steps.enumerated()), id: \.0) { idx, step in
                HStack(spacing: 12) {
                    Text("\(idx + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(accentColor)
                        .clipShape(Circle())
                    Text(step)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.08))
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.95, green: 0.97, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Previews

#Preview("Design Concepts") {
    DesignConceptsPreview()
}

#Preview("C1 Signal Red") { Concept1_SignalRed() }
#Preview("C2 Dark Shield") { Concept2_DarkShield() }
#Preview("C3 Breathing Room") { Concept3_BreathingRoom() }
#Preview("C4 Grid Map") { Concept4_GridMap() }
#Preview("C5 Soft Emergency") { Concept5_SoftEmergency() }
