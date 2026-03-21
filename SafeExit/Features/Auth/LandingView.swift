import SwiftUI

// MARK: - Root container

struct LandingView: View {
    @State private var showSignIn = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            if showSignIn {
                SignInView(showSignIn: $showSignIn)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                WelcomeOnboardingView(showSignIn: $showSignIn)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
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

            Rectangle()
                .fill(AppTheme.green)
                .frame(width: 40, height: 2)
                .padding(.top, 6)

            Spacer().frame(height: 24)

            IsometricRadarView()
                .frame(width: 300, height: 270)

            Spacer().frame(height: 20)

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

            HStack(spacing: 8) {
                LandingChip(icon: "mappin.circle.fill", label: "LIVE MAP")
                LandingChip(icon: "bolt.fill",          label: "FAST EXIT")
                LandingChip(icon: "shield.fill",        label: "SOS SYNC")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            Spacer()

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
                            .stroke(focus == .email ? AppTheme.green.opacity(0.45) : AppTheme.border, lineWidth: 1)
                    )
                }

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
                            .stroke(focus == .password ? AppTheme.green.opacity(0.45) : AppTheme.border, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 28)

            if let err = auth.signInError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(AppTheme.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 28)
            }

            Spacer()

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

// MARK: - Landing chip

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

// MARK: - Isometric radar graphic

private struct IsometricRadarView: View {
    var body: some View {
        ZStack {
            // Concentric radar rings
            ForEach([260, 200, 148, 96], id: \.self) { diameter in
                Circle()
                    .stroke(AppTheme.green.opacity(diameter == 260 ? 0.12 : 0.09), lineWidth: 1)
                    .frame(width: CGFloat(diameter), height: CGFloat(diameter))
            }

            // Radial glow behind building
            RadialGradient(
                colors: [AppTheme.green.opacity(0.07), Color.clear],
                center: .center, startRadius: 0, endRadius: 110
            )
            .frame(width: 220, height: 220)
            .clipShape(Circle())

            // Floor plan canvas
            IsoFloorPlanCanvas()
                .frame(width: 270, height: 200)

            // Floating icon cards — all dark bg, green icon
            IconCard(icon: "mappin.circle")
                .offset(x: 104, y: -90)

            IconCard(icon: "bolt.fill")
                .offset(x: 112, y: 18)

            IconCard(icon: "checkmark.shield.fill")
                .offset(x: -106, y: 72)
        }
    }
}

// MARK: - Isometric floor plan canvas

private struct IsoFloorPlanCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            // ── Projection parameters ──────────────────────────────────────
            let cx  = size.width  * 0.5
            let cy  = size.height * 0.48
            // Building grid: W × D units, isoW = half-diamond width in px
            let isoW: CGFloat = 84   // half diamond width
            let W:    CGFloat = 16   // grid units wide
            let D:    CGFloat = 10   // grid units deep
            let wH:   CGFloat = 17   // wall height px

            // Isometric projection: grid (gx,gy,gz) → screen CGPoint
            // Top vertex at (cx, cy - isoW*0.5)
            let yTop = cy - isoW * 0.5

            // Inline helper via nested function (captures local lets)
            func p(_ gx: CGFloat, _ gy: CGFloat, _ gz: CGFloat = 0) -> CGPoint {
                CGPoint(
                    x: cx  + (gx / W - gy / D) * isoW,
                    y: yTop + (gx / W + gy / D) * isoW * 0.5 - gz * wH
                )
            }

            // ── Colors ────────────────────────────────────────────────────
            let cHi  = Color(red: 0.20, green: 0.88, blue: 0.98)   // bright cyan
            let cMid = cHi.opacity(0.55)
            let cDim = cHi.opacity(0.28)
            let cFnt = cHi.opacity(0.10)                           // furniture fill
            let cWal = Color(red: 0.00, green: 0.30, blue: 0.45).opacity(0.16)  // wall fill
            let cFlr = Color(red: 0.00, green: 0.25, blue: 0.40).opacity(0.20)  // floor fill

            let lnTk = StrokeStyle(lineWidth: 1.0)
            let lnMd = StrokeStyle(lineWidth: 0.70)
            let lnTn = StrokeStyle(lineWidth: 0.50)

            // ── Floor fill ────────────────────────────────────────────────
            let floor = Path { q in
                q.move(to: p(0,0)); q.addLine(to: p(W,0))
                q.addLine(to: p(W,D)); q.addLine(to: p(0,D))
                q.closeSubpath()
            }
            ctx.fill(floor, with: .color(cFlr))

            // ── Outer right face  (gx = W) ────────────────────────────────
            let faceR = Path { q in
                q.move(to: p(W,0,0)); q.addLine(to: p(W,D,0))
                q.addLine(to: p(W,D,1)); q.addLine(to: p(W,0,1))
                q.closeSubpath()
            }
            ctx.fill(faceR, with: .color(cWal))
            ctx.stroke(faceR, with: .color(cMid), style: lnTk)

            // ── Outer front face (gy = D) ─────────────────────────────────
            let faceF = Path { q in
                q.move(to: p(0,D,0)); q.addLine(to: p(W,D,0))
                q.addLine(to: p(W,D,1)); q.addLine(to: p(0,D,1))
                q.closeSubpath()
            }
            ctx.fill(faceF, with: .color(cWal))
            ctx.stroke(faceF, with: .color(cMid), style: lnTk)

            // ── Interior vertical walls (constant gx) ─────────────────────
            // gx=5: left room divider (full depth)
            let wv1 = Path { q in
                q.move(to: p(5,0,0)); q.addLine(to: p(5,D,0))
                q.addLine(to: p(5,D,1)); q.addLine(to: p(5,0,1))
                q.closeSubpath()
            }
            ctx.fill(wv1, with: .color(cWal.opacity(0.5)))
            ctx.stroke(wv1, with: .color(cDim), style: lnMd)

            // gx=12: right room divider (full depth)
            let wv2 = Path { q in
                q.move(to: p(12,0,0)); q.addLine(to: p(12,D,0))
                q.addLine(to: p(12,D,1)); q.addLine(to: p(12,0,1))
                q.closeSubpath()
            }
            ctx.fill(wv2, with: .color(cWal.opacity(0.5)))
            ctx.stroke(wv2, with: .color(cDim), style: lnMd)

            // ── Interior horizontal walls (constant gy) ───────────────────
            // gy=4, gx: 0→5
            let wh1 = Path { q in
                q.move(to: p(0,4,0)); q.addLine(to: p(5,4,0))
                q.addLine(to: p(5,4,1)); q.addLine(to: p(0,4,1))
                q.closeSubpath()
            }
            ctx.fill(wh1, with: .color(cWal.opacity(0.4)))
            ctx.stroke(wh1, with: .color(cDim), style: lnTn)

            // gy=7, gx: 0→5
            let wh2 = Path { q in
                q.move(to: p(0,7,0)); q.addLine(to: p(5,7,0))
                q.addLine(to: p(5,7,1)); q.addLine(to: p(0,7,1))
                q.closeSubpath()
            }
            ctx.fill(wh2, with: .color(cWal.opacity(0.4)))
            ctx.stroke(wh2, with: .color(cDim), style: lnTn)

            // gy=3, gx: 5→12
            let wh3 = Path { q in
                q.move(to: p(5,3,0)); q.addLine(to: p(12,3,0))
                q.addLine(to: p(12,3,1)); q.addLine(to: p(5,3,1))
                q.closeSubpath()
            }
            ctx.fill(wh3, with: .color(cWal.opacity(0.4)))
            ctx.stroke(wh3, with: .color(cDim), style: lnTn)

            // gy=4, gx: 12→W
            let wh4 = Path { q in
                q.move(to: p(12,4,0)); q.addLine(to: p(W,4,0))
                q.addLine(to: p(W,4,1)); q.addLine(to: p(12,4,1))
                q.closeSubpath()
            }
            ctx.fill(wh4, with: .color(cWal.opacity(0.4)))
            ctx.stroke(wh4, with: .color(cDim), style: lnTn)

            // gy=7, gx: 12→W
            let wh5 = Path { q in
                q.move(to: p(12,7,0)); q.addLine(to: p(W,7,0))
                q.addLine(to: p(W,7,1)); q.addLine(to: p(12,7,1))
                q.closeSubpath()
            }
            ctx.fill(wh5, with: .color(cWal.opacity(0.4)))
            ctx.stroke(wh5, with: .color(cDim), style: lnTn)

            // ── Furniture (floor-level rects) ──────────────────────────────
            func furniRect(_ x1: CGFloat,_ y1: CGFloat,_ x2: CGFloat,_ y2: CGFloat) -> Path {
                Path { q in
                    q.move(to: p(x1,y1)); q.addLine(to: p(x2,y1))
                    q.addLine(to: p(x2,y2)); q.addLine(to: p(x1,y2))
                    q.closeSubpath()
                }
            }

            let furniture: [(CGFloat,CGFloat,CGFloat,CGFloat)] = [
                // left rooms: 3 desks
                (0.5, 0.5, 4.0, 2.0),
                (0.5, 4.5, 4.0, 6.2),
                (0.5, 7.5, 4.0, 9.2),
                // center corridor: storage unit
                (5.5, 0.3, 9.0, 1.6),
                // center main: conference table
                (5.8, 3.8, 10.5, 7.5),
                // conference chairs top row
                (6.2, 3.0, 7.1, 3.7),
                (7.6, 3.0, 8.5, 3.7),
                (9.0, 3.0, 9.9, 3.7),
                // conference chairs bottom row
                (6.2, 7.6, 7.1, 8.3),
                (7.6, 7.6, 8.5, 8.3),
                (9.0, 7.6, 9.9, 8.3),
                // right section: shelves + cabinets
                (12.5, 0.4, 15.5, 1.6),
                (12.5, 4.5, 15.5, 6.5),
                (12.5, 7.6, 15.5, 9.4),
            ]

            for (x1, y1, x2, y2) in furniture {
                let fr = furniRect(x1, y1, x2, y2)
                ctx.fill(fr, with: .color(cFnt))
                ctx.stroke(fr, with: .color(cMid), style: lnTn)
            }

            // ── Floor interior wall lines (top view) ──────────────────────
            let wallSegs: [(CGFloat,CGFloat,CGFloat,CGFloat)] = [
                (5,0,  5,D),   (12,0, 12,D),
                (0,4,  5,4),   (0,7,  5,7),
                (5,3,  12,3),  (12,4, W,4),  (12,7, W,7),
            ]
            for (x1,y1,x2,y2) in wallSegs {
                let ln = Path { q in q.move(to: p(x1,y1)); q.addLine(to: p(x2,y2)) }
                ctx.stroke(ln, with: .color(cMid), style: lnMd)
            }

            // ── Outer top edge (gz = 1) ───────────────────────────────────
            let topEdge = Path { q in
                q.move(to: p(0,0,1)); q.addLine(to: p(W,0,1))
                q.addLine(to: p(W,D,1)); q.addLine(to: p(0,D,1))
                q.closeSubpath()
            }
            ctx.stroke(topEdge, with: .color(cHi), style: lnTk)

            // ── Floor outer outline ───────────────────────────────────────
            ctx.stroke(floor, with: .color(cHi), style: lnTk)

            // ── Outer vertical corner lines ───────────────────────────────
            for (gx, gy) in [(CGFloat(0),CGFloat(0)),(W,0),(W,D),(0,D)] {
                let ln = Path { q in q.move(to: p(gx,gy,0)); q.addLine(to: p(gx,gy,1)) }
                ctx.stroke(ln, with: .color(cHi), style: lnTk)
            }

            // ── Interior top lines at gz=1 ────────────────────────────────
            for (x1,y1,x2,y2) in wallSegs {
                let ln = Path { q in q.move(to: p(x1,y1,1)); q.addLine(to: p(x2,y2,1)) }
                ctx.stroke(ln, with: .color(cDim), style: lnTn)
            }
        }
    }
}

// MARK: - Floating icon card

private struct IconCard: View {
    let icon: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBg2)
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.green)
        }
    }
}

#Preview("Landing") {
    LandingView()
        .environmentObject(AuthViewModel())
}
