import SwiftUI

struct ReportHazardView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ReportHazardType? = nil
    @State private var notes = ""
    @State private var submitted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("REPORT HAZARD")
                    .font(.system(size: 16, weight: .black))
                    .tracking(1)
                    .foregroundStyle(AppTheme.textPri)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textSec)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.cardBg2)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)

            if submitted {
                submittedState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Mark location
                        locationSection

                        // Hazard type grid
                        hazardTypeSection

                        // Add evidence
                        evidenceSection

                        // Notes
                        notesSection

                        // Submit
                        submitSection

                        // Warning
                        Text("MISUSE OF EMERGENCY REPORTING IS A SAFETY VIOLATION.\nALL REPORTS ARE LOGGED WITH YOUR LOCATION.")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                            .foregroundStyle(AppTheme.textDim)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Sections

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(AppTheme.green)
                Text("MARK LOCATION")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
                Spacer()
                if let node = viewModel.currentStartNode,
                   let building = viewModel.buildingPackage {
                    Text("\(building.metadata.name) · \(node.name)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.greenDim)
                        .clipShape(Capsule())
                }
            }

            // Mini map pin area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBg2)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))

                VStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.red)
                    Text("LONG-PRESS MAP TO ADJUST PIN POSITION")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppTheme.textDim)
                }
            }
        }
    }

    private var hazardTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HAZARD TYPE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ReportHazardType.allCases) { type in
                    Button { selectedType = type } label: {
                        VStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.system(size: 28))
                                .foregroundStyle(selectedType == type ? AppTheme.bg : AppTheme.textSec)
                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(selectedType == type ? AppTheme.bg : AppTheme.textSec)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selectedType == type ? AppTheme.green : AppTheme.cardBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedType == type
                                        ? AppTheme.green : AppTheme.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADD EVIDENCE")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBg2)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    )
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.textDim)
                    Text("ATTACH PHOTO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppTheme.textDim)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADDITIONAL NOTES")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBg2)
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                if notes.isEmpty {
                    Text("Briefly describe the situation (e.g., 'Blocked exit', 'Electrical sparks')")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textDim)
                        .padding(14)
                }
                TextEditor(text: $notes)
                    .foregroundStyle(AppTheme.textPri)
                    .font(.system(size: 13))
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(height: 90)
            }
        }
    }

    private var submitSection: some View {
        Button {
            guard let type = selectedType else { return }
            submitReport(type: type)
        } label: {
            Text("SUBMIT REPORT")
                .font(.system(size: 15, weight: .black))
                .tracking(1)
                .foregroundStyle(selectedType != nil ? AppTheme.textPri : AppTheme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(selectedType != nil ? AppTheme.cardBg3 : AppTheme.cardBg2)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(selectedType != nil ? AppTheme.textSec.opacity(0.3) : AppTheme.border,
                                lineWidth: 1)
                )
        }
        .disabled(selectedType == nil)
    }

    private var submittedState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.green)
            Text("Report Submitted")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AppTheme.textPri)
            Text("Your hazard report has been logged.\nThe routing engine is recalculating safe paths.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
            Spacer()
            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Submit logic (connects to real hazard engine)

    private func submitReport(type: ReportHazardType) {
        guard let building = viewModel.buildingPackage else { return }

        let matchID: String?
        switch type {
        case .fire:
            matchID = building.hazardTemplates
                .first(where: { $0.title.lowercased().contains("main") })?.id
        case .smoke:
            matchID = building.hazardTemplates
                .first(where: { $0.title.lowercased().contains("smoke") })?.id
        case .debris:
            matchID = building.hazardTemplates
                .first(where: { $0.title.lowercased().contains("side") })?.id
        case .other:
            matchID = building.hazardTemplates.last?.id
        }

        if let id = matchID {
            viewModel.toggleHazard(id, enabled: true)
        }
        withAnimation { submitted = true }
    }
}

// MARK: - Hazard type model

enum ReportHazardType: String, CaseIterable, Identifiable {
    case fire   = "FIRE"
    case smoke  = "SMOKE"
    case debris = "DEBRIS"
    case other  = "OTHER"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fire:   return "flame.fill"
        case .smoke:  return "smoke.fill"
        case .debris: return "xmark.app.fill"
        case .other:  return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    ReportHazardView()
        .environmentObject(AppViewModel(container: AppContainer.makeDefault()))
}
