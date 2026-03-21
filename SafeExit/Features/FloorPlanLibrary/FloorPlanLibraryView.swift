import SwiftUI
import PhotosUI

// MARK: - Data model

struct FloorPlanEntry: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var floorLabel: String
    var status: FloorPlanStatus
    var lastModified: Date
}

enum FloorPlanStatus: String, Codable, CaseIterable {
    case active   = "Active"
    case syncing  = "Syncing"
    case draft    = "Draft"

    var color: Color {
        switch self {
        case .active:  return AppTheme.green
        case .syncing: return AppTheme.amber
        case .draft:   return AppTheme.textSec
        }
    }

    var icon: String {
        switch self {
        case .active:  return "checkmark.circle.fill"
        case .syncing: return "arrow.clockwise"
        case .draft:   return "circle"
        }
    }
}

// MARK: - Shared view model (provided as @EnvironmentObject from MainTabView)

@MainActor
final class FloorPlanLibraryViewModel: ObservableObject {
    @Published var entries:    [FloorPlanEntry] = []
    @Published var searchText  = ""
    @Published var syncStatus: SyncStatus       = .idle
    @Published private(set) var activeMapID:    String?
    @Published private(set) var activeMapImage: UIImage?

    private let db = FirestoreService.shared

    var filtered: [FloorPlanEntry] {
        searchText.isEmpty ? entries : entries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        loadLocal()
        restoreActiveMap()
        Task { await loadFromFirestore() }
    }

    // MARK: - Firestore + Storage sync

    func loadFromFirestore() async {
        syncStatus = .syncing
        do {
            let records = try await db.fetchFloorPlanRecords()
            var merged  = entries
            for record in records {
                let entry = FloorPlanEntry(
                    id:           record.id,
                    name:         record.name,
                    floorLabel:   record.floorLabel,
                    status:       FloorPlanStatus(rawValue: record.status) ?? .draft,
                    lastModified: record.lastModified
                )
                if let i = merged.firstIndex(where: { $0.id == record.id }) {
                    merged[i] = entry
                } else {
                    merged.append(entry)
                }
                // Download image from Storage if not cached locally
                if thumbnail(for: record.id) == nil, let urlStr = record.imageURL {
                    if let img = try? await db.downloadFloorPlanImage(url: urlStr) {
                        saveImage(img, id: record.id)
                    }
                }
            }
            merged.sort { $0.lastModified > $1.lastModified }
            entries = merged
            persistLocal()
            restoreActiveMap()
            syncStatus = .synced
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    // MARK: - Public actions

    /// Import a new map — saves locally, uploads image to Firebase Storage, writes metadata to Firestore.
    func add(name: String, floorLabel: String, image: UIImage) {
        let entry = FloorPlanEntry(name: name, floorLabel: floorLabel,
                                   status: .active, lastModified: Date())
        saveImage(image, id: entry.id)

        // New map takes over as active; push previous active to draft
        for i in entries.indices where entries[i].status == .active {
            entries[i].status = .draft
        }
        activeMapID    = entry.id
        activeMapImage = image
        UserDefaults.standard.set(entry.id, forKey: "active_map_id")

        entries.insert(entry, at: 0)
        persistLocal()
        firestoreSync { [weak self] in
            guard let self else { return }
            // 1 — Upload full image to Firebase Storage
            let imageURL = try await self.db.uploadFloorPlanImage(image, id: entry.id)
            // 2 — Save metadata + download URL to Firestore
            let record = FloorPlanRecord(
                id:           entry.id,
                name:         entry.name,
                floorLabel:   entry.floorLabel,
                status:       entry.status.rawValue,
                lastModified: entry.lastModified,
                imageURL:     imageURL
            )
            try await self.db.saveFloorPlanRecord(record)
            // 3 — Update previously-active entries to Draft in Firestore
            for e in self.entries where e.status == .draft && e.id != entry.id {
                try await self.db.updateFloorPlanFields(id: e.id, fields: ["status": "Draft"])
            }
        }
    }

    /// Set a map as the active live map. All others become Draft.
    func setActive(_ entry: FloorPlanEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        for i in entries.indices {
            entries[i].status = entries[i].id == entry.id ? .active
                : (entries[i].status == .active ? .draft : entries[i].status)
        }
        entries[idx].lastModified = Date()
        activeMapID    = entry.id
        activeMapImage = thumbnail(for: entry.id)
        UserDefaults.standard.set(entry.id, forKey: "active_map_id")
        persistLocal()
        let snapshot = entries
        firestoreSync { [weak self] in
            guard let self else { return }
            for e in snapshot {
                try await self.db.updateFloorPlanFields(
                    id: e.id,
                    fields: ["status": e.status.rawValue,
                             "lastModified": e.lastModified]
                )
            }
        }
    }

    /// Deactivate a map (sets it to Draft). Live map goes blank.
    func deactivate(_ entry: FloorPlanEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx].status       = .draft
        entries[idx].lastModified = Date()
        if activeMapID == entry.id {
            activeMapID    = nil
            activeMapImage = nil
            UserDefaults.standard.removeObject(forKey: "active_map_id")
        }
        persistLocal()
        let updated = entries[idx]
        firestoreSync { [weak self] in
            try await self?.db.updateFloorPlanFields(
                id: updated.id,
                fields: ["status": updated.status.rawValue,
                         "lastModified": updated.lastModified]
            )
        }
    }

    func setStatusOnly(_ status: FloorPlanStatus, for entry: FloorPlanEntry) {
        switch status {
        case .active:           setActive(entry)
        case .draft, .syncing:  deactivate(entry); setStatusDirect(status, id: entry.id)
        }
    }

    func rename(_ entry: FloorPlanEntry, to name: String) {
        guard let i = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[i].name         = name
        entries[i].lastModified = Date()
        persistLocal()
        let updated = entries[i]
        firestoreSync { [weak self] in
            try await self?.db.updateFloorPlanFields(
                id: updated.id,
                fields: ["name": updated.name, "lastModified": updated.lastModified]
            )
        }
    }

    func delete(_ entry: FloorPlanEntry) {
        if activeMapID == entry.id {
            activeMapID    = nil
            activeMapImage = nil
            UserDefaults.standard.removeObject(forKey: "active_map_id")
        }
        entries.removeAll { $0.id == entry.id }
        deleteImage(id: entry.id)
        persistLocal()
        firestoreSync { [weak self] in
            guard let self else { return }
            // Delete both the Firestore document and the Storage image
            try await self.db.deleteFloorPlanRecord(id: entry.id)
            try? await self.db.deleteFloorPlanImage(id: entry.id)  // best-effort
        }
    }

    func thumbnail(for id: String) -> UIImage? {
        guard let url = imageURL(for: id), let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Switch the currently viewed map without changing any status in Firestore.
    /// Used by the map-switcher widget so employees can browse all floor plans.
    func viewMap(_ entry: FloorPlanEntry) {
        activeMapID    = entry.id
        activeMapImage = thumbnail(for: entry.id)
        UserDefaults.standard.set(entry.id, forKey: "active_map_id")
        // Download image in background if not cached locally
        if activeMapImage == nil {
            Task {
                if let records = try? await db.fetchFloorPlanRecords(),
                   let record  = records.first(where: { $0.id == entry.id }),
                   let urlStr  = record.imageURL,
                   let img     = try? await db.downloadFloorPlanImage(url: urlStr) {
                    saveImage(img, id: entry.id)
                    activeMapImage = img
                }
            }
        }
    }

    func relativeTime(from date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60      { return "just now" }
        if diff < 3600    { return "\(Int(diff / 60))m ago" }
        if diff < 86400   { return "\(Int(diff / 3600))h ago" }
        if diff < 172800  { return "Yesterday" }
        return "\(Int(diff / 86400)) days ago"
    }

    // MARK: - Helpers

    private func firestoreSync(_ work: @escaping () async throws -> Void) {
        Task { [weak self] in
            self?.syncStatus = .syncing
            do {
                try await work()
                self?.syncStatus = .synced
            } catch {
                self?.syncStatus = .error(error.localizedDescription)
            }
        }
    }

    private func setStatusDirect(_ status: FloorPlanStatus, id: String) {
        guard let i = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[i].status = status
        persistLocal()
        firestoreSync { [weak self] in
            try await self?.db.updateFloorPlanFields(id: id, fields: ["status": status.rawValue])
        }
    }

    private func restoreActiveMap() {
        let savedID = UserDefaults.standard.string(forKey: "active_map_id")
        if let id = savedID, entries.contains(where: { $0.id == id }) {
            activeMapID    = id
            activeMapImage = thumbnail(for: id)
            for i in entries.indices {
                if entries[i].id == id { entries[i].status = .active }
                else if entries[i].status == .active { entries[i].status = .draft }
            }
        }
    }

    // MARK: - Local persistence

    private func imageURL(for id: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("fp_\(id).jpg")
    }

    private func saveImage(_ image: UIImage, id: String) {
        guard let url  = imageURL(for: id),
              let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func deleteImage(id: String) {
        guard let url = imageURL(for: id) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private let storeKey = "floorplan_library_v1"

    private func persistLocal() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storeKey)
    }

    private func loadLocal() {
        guard let data    = UserDefaults.standard.data(forKey: storeKey),
              let decoded = try? JSONDecoder().decode([FloorPlanEntry].self, from: data) else { return }
        entries = decoded
    }
}

// MARK: - Main view

struct FloorPlanLibraryView: View {
    @EnvironmentObject private var vm: FloorPlanLibraryViewModel

    @State private var showImportSheet = false
    @State private var entryToDelete: FloorPlanEntry?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textDim)
                    TextField("Search floorplans...", text: $vm.searchText)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textPri)
                        .tint(AppTheme.green)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.cardBg2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Header row
                HStack {
                    Text("RECENT MAPS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(AppTheme.textSec)
                    Spacer()
                    // Firestore sync indicator
                    Image(systemName: vm.syncStatus.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(vm.syncStatus.color)
                    Text("\(vm.entries.count) Total")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSec)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardBg2)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if vm.filtered.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppTheme.textDim)
                                Text("No floor plans yet")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.textSec)
                                Text("Tap + to import your first map")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.textDim)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }

                        ForEach(vm.filtered) { entry in
                            MapCard(entry: entry, vm: vm, onDelete: { entryToDelete = entry })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }

            // FAB — opens Import Floorplan sheet
            Button { showImportSheet = true } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.green)
                        .frame(width: 56, height: 56)
                        .shadow(color: AppTheme.green.opacity(0.35), radius: 14, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showImportSheet) {
            ImportFloorplanSheet(vm: vm)
                .presentationBackground(AppTheme.bg)
        }
        .confirmationDialog(
            "Delete \"\(entryToDelete?.name ?? "")\"?",
            isPresented: .init(get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let e = entryToDelete { vm.delete(e) }
                entryToDelete = nil
            }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        }
    }
}

// MARK: - Map card

private struct MapCard: View {
    let entry: FloorPlanEntry
    @ObservedObject var vm: FloorPlanLibraryViewModel
    let onDelete: () -> Void

    @State private var thumbnail: UIImage?
    private var isActive: Bool { entry.status == .active }

    var body: some View {
        HStack(spacing: 0) {
            // Thumbnail with floor label badge
            ZStack(alignment: .bottomLeading) {
                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 114, height: 82)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppTheme.cardBg2)
                        .frame(width: 114, height: 82)
                        .overlay(
                            Image(systemName: "map")
                                .font(.system(size: 24))
                                .foregroundStyle(AppTheme.textDim)
                        )
                }

                Text(entry.floorLabel)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
            }
            .frame(width: 114, height: 82)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPri)
                        .lineLimit(1)

                    // "LIVE" badge for active map
                    if isActive {
                        Text("LIVE")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.green)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 5) {
                    Image(systemName: entry.status.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(entry.status.color)
                    Text(entry.status.rawValue)
                        .font(.system(size: 13))
                        .foregroundStyle(entry.status.color)
                }

                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textDim)
                    Text("Modified \(vm.relativeTime(from: entry.lastModified))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textDim)
                }
            }
            .padding(.leading, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Three-dot menu
            Menu {
                if !isActive {
                    Button {
                        vm.setActive(entry)
                    } label: {
                        Label("Set as Live Map", systemImage: "checkmark.circle.fill")
                    }
                } else {
                    Button {
                        vm.deactivate(entry)
                    } label: {
                        Label("Deactivate", systemImage: "circle")
                    }
                }
                Button { vm.setStatusOnly(.syncing, for: entry) } label: {
                    Label("Set Syncing", systemImage: "arrow.clockwise")
                }
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.textSec)
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
            .padding(.trailing, 4)
        }
        .frame(height: 82)
        .background(isActive ? AppTheme.greenDim : AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? AppTheme.green.opacity(0.5) : AppTheme.border, lineWidth: isActive ? 1.5 : 1)
        )
        .onAppear { thumbnail = vm.thumbnail(for: entry.id) }
    }
}

// MARK: - Import Floorplan Sheet

private enum ImportSource: CaseIterable {
    case cloud, localFile, cameraScan

    var label: String {
        switch self {
        case .cloud:      return "Cloud"
        case .localFile:  return "Local File"
        case .cameraScan: return "Camera Scan"
        }
    }
    var sub: String {
        switch self {
        case .cloud:      return "Drive / Dropbox"
        case .localFile:  return "PDF / High-res JPG"
        case .cameraScan: return "Instant scan of printed architectural blueprints"
        }
    }
    var icon: String {
        switch self {
        case .cloud:      return "cloud"
        case .localFile:  return "doc.badge.arrow.up"
        case .cameraScan: return "camera"
        }
    }
    var isWide: Bool { self == .cameraScan }
}

private struct ImportFloorplanSheet: View {
    @ObservedObject var vm: FloorPlanLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSource: ImportSource = .localFile
    @State private var buildingName = ""
    @State private var floorNumber  = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var isUploading  = false

    private var canUpload: Bool {
        pendingImage != nil && !buildingName.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textSec)
                    }
                    Text("Import Floorplan")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPri)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider().background(AppTheme.divider)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── IMPORT SOURCE ──
                        importSourceSection

                        Divider().background(AppTheme.divider)

                        // ── MAP DETAILS ──
                        mapDetailsSection

                        Divider().background(AppTheme.divider)

                        // ── PREVIEW ──
                        previewSection

                        // ── INFO BOX ──
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Acceptable Formats")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.textPri)
                                Text("Ensure maps are high-contrast. Supported formats: PDF (Vector preferred), PNG, or JPEG. Maximum file size: 25MB.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.textSec)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                        .background(AppTheme.greenDim)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.green.opacity(0.2), lineWidth: 1))

                        // ── BUTTONS ──
                        Button {
                            processAndUpload()
                        } label: {
                            HStack(spacing: 8) {
                                if isUploading {
                                    ProgressView()
                                        .tint(.black)
                                        .scaleEffect(0.8)
                                }
                                Text("Process & Upload")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canUpload ? AppTheme.green : AppTheme.textDim)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!canUpload || isUploading)

                        Button { dismiss() } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.textSec)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.cardBg2)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppTheme.border, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: photoItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    pendingImage = img
                }
            }
        }
    }

    // MARK: - Import Source Section

    private var importSourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
                Text("IMPORT SOURCE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
            }

            // Cloud + Local File row
            HStack(spacing: 10) {
                ForEach([ImportSource.cloud, .localFile], id: \.label) { source in
                    sourceButton(source)
                }
            }

            // Camera Scan — full width, uses PhotosPicker
            PhotosPicker(selection: $photoItem, matching: .images) {
                VStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 24))
                        .foregroundStyle(selectedSource == .cameraScan ? .black : AppTheme.textSec)
                    Text("Camera Scan")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedSource == .cameraScan ? .black : AppTheme.textPri)
                    Text("Instant scan of printed architectural blueprints")
                        .font(.system(size: 11))
                        .foregroundStyle(selectedSource == .cameraScan
                                         ? .black.opacity(0.6) : AppTheme.textDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedSource == .cameraScan ? AppTheme.green : AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(selectedSource == .cameraScan
                            ? AppTheme.green : AppTheme.border, lineWidth: 1))
            }
            .simultaneousGesture(TapGesture().onEnded { selectedSource = .cameraScan })
        }
    }

    private func sourceButton(_ source: ImportSource) -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 8) {
                Image(systemName: source.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(selectedSource == source ? .black : AppTheme.textSec)
                Text(source.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selectedSource == source ? .black : AppTheme.textPri)
                Text(source.sub)
                    .font(.system(size: 11))
                    .foregroundStyle(selectedSource == source
                                     ? .black.opacity(0.6) : AppTheme.textDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(selectedSource == source ? AppTheme.green : AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selectedSource == source
                        ? AppTheme.green : AppTheme.border, lineWidth: 1))
        }
        .simultaneousGesture(TapGesture().onEnded { selectedSource = source })
    }

    // MARK: - Map Details Section

    private var mapDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "building.2")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
                Text("MAP DETAILS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(AppTheme.textSec)
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Building Name")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                    TextField("Main Hospital Complex", text: $buildingName)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textPri)
                        .tint(AppTheme.green)
                        .padding(12)
                        .background(AppTheme.cardBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.border, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Floor Number")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                    TextField("2", text: $floorNumber)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textPri)
                        .tint(AppTheme.green)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(AppTheme.cardBg2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.border, lineWidth: 1))
                }

                Text("* Must correspond to existing building schematics for route calculation.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textDim)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(AppTheme.textDim.opacity(0.4), lineWidth: 1))
            }
            .padding(16)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.green.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREVIEW")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(AppTheme.textSec)

            VStack(spacing: 12) {
                if let img = pendingImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text("Staged")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.cardBg2)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.green.opacity(0.3), lineWidth: 1))
                            .padding(8)
                    }

                    Text(buildingName.isEmpty ? "unnamed_scan.jpg" : "\(buildingName.lowercased().replacingOccurrences(of: " ", with: "_")).jpg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPri)
                    Text("Ready for hazard processing")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textSec)

                    // Green progress bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.green)
                        .frame(height: 3)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.textDim)
                        Text("No file selected")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textSec)
                        Text("Choose an import source above")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textDim)
                    }
                    .padding(.vertical, 30)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundStyle(pendingImage != nil ? AppTheme.green.opacity(0.4) : AppTheme.textDim)
            )
        }
    }

    // MARK: - Upload

    private func processAndUpload() {
        guard let img = pendingImage, !buildingName.isEmpty else { return }
        isUploading = true

        let floor = floorNumber.isEmpty ? "FL" : "FL \(floorNumber)"
        vm.add(name: buildingName, floorLabel: floor, image: img)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isUploading = false
            dismiss()
        }
    }
}

#Preview {
    FloorPlanLibraryView()
        .environmentObject(FloorPlanLibraryViewModel())
}
