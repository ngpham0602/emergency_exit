# Saferoute — Emergency Evacuation Routing App

Saferoute is an iOS application that provides real-time, hazard-aware evacuation routing for buildings. It uses graph-based pathfinding (Dijkstra's algorithm) to compute the safest exit route, dynamically rerouting when hazards are reported. Built with SwiftUI, Firebase, and a custom routing engine.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Data Models](#data-models)
- [Routing Engine](#routing-engine)
- [Firebase Integration](#firebase-integration)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Testing](#testing)
- [Team](#team)

---

## Features

### Core
- **Hazard-aware pathfinding** — Dijkstra's algorithm with severity-weighted penalties (blocked = impassable, high-risk = 5x penalty)
- **Real-time rerouting** — Routes recalculate instantly when hazards are toggled, reported, or cleared
- **Accessibility mode** — Wheelchair-safe routing that excludes stairs and non-accessible paths
- **Multi-destination fallback** — Routes to exits first; falls back to refuge points when all exits are blocked

### Map & Visualization
- **Interactive live map** — Canvas-rendered floor plan with nodes, edges, route path, and hazard indicators
- **Map editor** — Place, connect, and manage custom nodes with Firestore sync and proximity-based auto-connection
- **Floor plan library** — Import, manage, and switch between multiple floor plan images with Firebase Storage upload
- **Pinch-to-zoom & pan** — Full gesture support on both the map editor and hazard report map

### Hazard Reporting
- **Report hazards** — Select a node on the interactive map, choose hazard type (fire, smoke, debris, other), and submit
- **Firestore-backed nodes** — Hazard map loads nodes from Firebase, matching the map editor's data
- **Severity mapping** — Fire/debris = blocked (impassable), smoke/other = high-risk (penalized)
- **Ad-hoc hazard placement** — Tap any node on the live map in "Danger Here" mode to place hazards with severity picker

### Emergency Mode
- **Full-screen emergency alert** — Red emergency view with immediate action cards and SOS hold-to-trigger siren
- **Quick actions** — Share location, call emergency services, find nearby safe zones
- **False alarm reset** — Clears all hazards and returns to normal operation

### User Management
- **Role-based access** — Security personnel get admin panel + floor plan management; employees get map + route views
- **Firebase Auth** — Email/password authentication with role stored in Firestore
- **Profile** — User info, safety contacts, preference toggles (accessibility, audio guidance, biometric lock)

---

## Screenshots

| Live Map | Report Hazard | Import Floorplan | Emergency Mode |
|----------|---------------|------------------|----------------|
| Interactive floor plan with route | Tap node to set hazard location | Cloud, local file, or camera scan | Full-screen alert with SOS |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  SaferouteApp                     │
│         (Firebase init, auth gate)               │
├────────────────────┬────────────────────────────┤
│   LandingView      │      MainTabView           │
│   (Auth flow)      │  ┌─────────────────────┐   │
│                    │  │ Map  Plans  Admin    │   │
│                    │  │ Route  Profile       │   │
│                    │  └─────────────────────┘   │
├────────────────────┴────────────────────────────┤
│              AppViewModel (Central State)        │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Building │  │  Route   │  │    Hazard     │  │
│  │ Package  │  │  Result  │  │    State      │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
├─────────────────────────────────────────────────┤
│                 AppContainer (DI)                │
│  ┌──────────────┐ ┌────────────┐ ┌───────────┐  │
│  │ Building     │ │  Routing   │ │  Hazard   │  │
│  │ Repository   │ │  Engine    │ │  Manager  │  │
│  └──────────────┘ └────────────┘ └───────────┘  │
├─────────────────────────────────────────────────┤
│            FirestoreService.shared               │
│   Buildings · Floors · Nodes · Edges · Hazards   │
│   Floor Plans · Map Editor · Firebase Storage    │
└─────────────────────────────────────────────────┘
```

**Pattern:** MVVM with dependency injection via `AppContainer`. Views observe `AppViewModel` and `FloorPlanLibraryViewModel` as `@EnvironmentObject`. All Firestore access is centralized through `FirestoreService.shared`.

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5 |
| **UI Framework** | SwiftUI (iOS 17+) |
| **Minimum Deployment** | iOS 17.0 |
| **Authentication** | Firebase Auth (email/password) |
| **Database** | Cloud Firestore |
| **File Storage** | Firebase Storage |
| **Pathfinding** | Custom Dijkstra's algorithm |
| **Rendering** | SwiftUI Canvas (2D graph drawing) |
| **Package Manager** | Swift Package Manager |
| **Dependency** | `firebase-ios-sdk` 12.11.0 |

---

## Project Structure

```
Saferoute/
├── App/
│   ├── SaferouteApp.swift              # Entry point, Firebase init, auth gate
│   ├── AppContainer.swift             # Dependency injection container
│   ├── AppViewModel.swift             # Central state: building, route, hazards
│   ├── AuthViewModel.swift            # Firebase Auth + role management
│   ├── AppTheme.swift                 # Design system (colors, typography)
│   └── RootTabView.swift              # Root navigation
│
├── Core/
│   ├── Graph/
│   │   └── RoutingEngine.swift        # Dijkstra pathfinding with hazard weights
│   ├── Models/
│   │   ├── BuildingPackage.swift      # Node, Edge, Exit, RefugePoint, Floor
│   │   ├── HazardModels.swift         # HazardEvent, Severity, Status, Confidence
│   │   ├── RouteModels.swift          # RouteResult, RouteInstruction
│   │   ├── Building.swift             # Firestore building model
│   │   ├── Floor.swift                # Firestore floor model
│   │   ├── MapNode.swift              # Firestore node model (%-based coords)
│   │   ├── MapEdge.swift              # Firestore edge model
│   │   └── Hazard.swift               # Firestore hazard report model
│   └── Services/
│       ├── FirestoreService.swift     # All Firestore/Storage operations
│       ├── BuildingPackageRepository.swift  # JSON loader for demo data
│       └── HazardStateManager.swift   # In-memory hazard state tracking
│
├── Features/
│   ├── Auth/
│   │   └── LandingView.swift          # 4-step onboarding + auth flow
│   ├── Main/
│   │   ├── MainTabView.swift          # Role-based tab navigation
│   │   └── FirebaseTestView.swift     # Debug: test Firestore read/write
│   ├── Map/
│   │   ├── LiveMapView.swift          # Interactive map with FloorPlanCanvas
│   │   └── MapEditorView.swift        # Node/edge editor with Firestore sync
│   ├── FloorPlanLibrary/
│   │   └── FloorPlanLibraryView.swift # Import, manage, switch floor plans
│   ├── Route/
│   │   └── RouteDetailView.swift      # Step-by-step route with alt paths
│   ├── Routing/
│   │   └── RouteOverviewView.swift    # Route overview with room picker
│   ├── Hazard/
│   │   └── ReportHazardView.swift     # Report hazard with Firestore map
│   ├── EmergencyMode/
│   │   ├── EmergencyActiveView.swift  # Full-screen emergency alert + SOS
│   │   └── EmergencyGuidanceView.swift # Evacuation guidance display
│   ├── AdminPanel/
│   │   └── AdminHazardPanelView.swift # Security: toggle demo hazards
│   ├── Profile/
│   │   └── ProfileView.swift          # User profile, contacts, preferences
│   ├── Settings/
│   │   └── SettingsView.swift         # Accessibility + building info
│   ├── LocationSelection/
│   │   └── LocationSelectionView.swift # Room picker component
│   └── DesignPreview/
│       └── DesignConceptsPreview.swift # Design system preview
│
├── Resources/
│   ├── GoogleService-Info.plist       # Firebase configuration
│   ├── BuildingPackages/
│   │   └── demo_building.json         # Sample building with 8 nodes, 7 edges
│   └── QRSeeds/
│       └── qr_seeds.json              # QR code seed data
│
SaferouteTests/
└── RoutingEngineTests.swift           # 4 unit tests for pathfinding
```

---

## Data Models

### Building Graph (Local JSON)

```
BuildingPackage
├── metadata        — name, version, description
├── floors[]        — floor ID, label, level number
├── nodes[]         — id, name, type, floor, coordinates (x, y)
├── edges[]         — id, from/to node IDs, distance, type, accessibility
├── exits[]         — id, node ID, type (primary/secondary), status
├── refugePoints[]  — id, node ID, capacity note, instructions
├── hazardTemplates[] — pre-configured hazard scenarios
└── defaultStartNodeID
```

**Node Types:** `room` · `intersection` · `stairwell` · `lift` · `exit` · `refugePoint`

**Edge Types:** `corridor` · `stair` · `lift` · `doorway`

### Firestore Models

| Model | Collection Path | Key Fields |
|-------|----------------|------------|
| `Building` | `buildings/` | name, address, type, verified, confidenceScore |
| `Floor` | `buildings/{id}/floors/` | floorNumber, floorLabel, mapImageURL, analysisStatus |
| `MapNode` | `buildings/{id}/floors/{id}/nodes/` | type, label, xPercent, yPercent, isAccessible, isExit |
| `MapEdge` | `buildings/{id}/floors/{id}/edges/` | fromNodeId, toNodeId, distanceMeters, isBlocked, hazardPenalty |
| `CustomNode` | `mapEditor/{mapID}/nodes/` | nx, ny (normalized 0-1), isDanger, isExit, label |
| `CustomEdge` | `mapEditor/{mapID}/edges/` | fromID, toID, isDanger |
| `Hazard` | `hazards/` | buildingId, floorId, type, xPercent, yPercent, confidence, expiresAt |
| `FloorPlanRecord` | `floorPlans/` | name, floorLabel, status, lastModified, imageURL |

---

## Routing Engine

### Algorithm: Dijkstra's Shortest Path with Hazard Penalty Weighting

```
1. Build weighted graph from building nodes + edges
2. Apply hazard penalties:
   ┌─────────────────┬──────────────┬─────────────────────┐
   │ Severity        │ Multiplier   │ Effect              │
   ├─────────────────┼──────────────┼─────────────────────┤
   │ blocked         │ ∞ (infinity) │ Path is impassable  │
   │ highRisk        │ 5.0×         │ Path is penalized   │
   │ inaccessible    │ ∞ (infinity) │ Blocks wheelchairs  │
   └─────────────────┴──────────────┴─────────────────────┘
3. If accessibility mode: exclude stairs + non-accessible edges
4. Run Dijkstra to all available exits
5. If no exit reachable: run Dijkstra to refuge points
6. Generate turn-by-turn instructions from path nodes
7. Return RouteResult with path, distance, destination, instructions
```

### Route Priority
1. **Available exits** (shortest weighted path)
2. **Refuge points** (fallback when all exits blocked)
3. **Error** (no route available)

---

## Firebase Integration

### Collections

```
Firestore (saferoute-a181d)
├── buildings/                          # Building metadata
│   └── {buildingId}/
│       └── floors/                     # Floor definitions
│           └── {floorId}/
│               ├── nodes/              # Map nodes (%-based coords)
│               └── edges/              # Map connectivity
├── mapEditor/                          # Custom map editor data
│   └── {mapID}/
│       ├── nodes/                      # User-placed nodes (normalized 0-1)
│       └── edges/                      # User-drawn connections
├── floorPlans/                         # Floor plan metadata
├── hazards/                            # User-reported hazards
│
Storage (saferoute-a181d.firebasestorage.app)
└── floorPlans/{id}.jpg                 # Uploaded floor plan images
```

### Key Operations
- **Real-time hazard listener** — `listenToHazards(floorId:onChange:)` returns `ListenerRegistration`
- **Batch node/edge saves** — Uses Firestore batch writes for consistency
- **Image upload** — JPEG compression at 0.85 quality to Firebase Storage
- **Offline-first** — Local UserDefaults persistence with Firestore sync

---

## Getting Started

### Prerequisites
- **Xcode 15+** (Swift 5, SwiftUI)
- **iOS 17.0+** deployment target
- **Firebase project** configured with Auth, Firestore, and Storage
- **CocoaPods** is not used — dependencies managed via SPM

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd emergency_exit
   ```

2. **Open in Xcode**
   ```bash
   open Saferoute.xcodeproj
   ```

3. **Resolve packages**
   Xcode will automatically fetch the Firebase iOS SDK (v12.11.0) via Swift Package Manager.

4. **Firebase configuration**
   The project includes a `GoogleService-Info.plist` pointing to the `saferoute-a181d` Firebase project. To use your own Firebase project:
   - Create a new project at [Firebase Console](https://console.firebase.google.com)
   - Enable **Authentication** (Email/Password)
   - Enable **Cloud Firestore**
   - Enable **Firebase Storage**
   - Download your `GoogleService-Info.plist` and replace the existing one in `Saferoute/Resources/`

5. **Build and run**
   Select an iOS 17+ simulator and press `Cmd + R`.

---

## Configuration

### Firebase Project
| Key | Value |
|-----|-------|
| Project ID | `saferoute-a181d` |
| Bundle ID | `com.codex.Saferoute` |
| Storage Bucket | `saferoute-a181d.firebasestorage.app` |

### Design System (`AppTheme`)
| Token | Value | Usage |
|-------|-------|-------|
| `bg` | `#000000` | App background |
| `cardBg` | `#171717` | Card backgrounds |
| `cardBg2` | `#212121` | Secondary card backgrounds |
| `cardBg3` | `#292929` | Tertiary card backgrounds |
| `green` | `#38F54A` | Primary accent (routes, success) |
| `red` | `#E64040` | Danger accent (hazards, alerts) |
| `amber` | `#F59E0A` | Warning accent (exits, refuge) |
| `textPri` | `#FFFFFF` | Primary text |
| `textSec` | `#808080` | Secondary text |
| `textDim` | `#525252` | Dimmed text |

### User Roles
| Role | Tabs | Capabilities |
|------|------|--------------|
| **Security** | Map, Plans, Admin, Route, Profile | Full access: manage floor plans, toggle hazards, admin panel |
| **Employee** | Map, Route, Profile | View map, follow routes, report hazards |

---

## Testing

### Unit Tests
The project includes 4 routing engine tests in `SaferouteTests/RoutingEngineTests.swift`:

```bash
# Run tests via Xcode
Cmd + U

# Or via command line
xcodebuild test \
  -scheme Saferoute \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

| Test | Validates |
|------|-----------|
| `testNormalRouteFindsAvailableExit` | Basic routing to nearest exit |
| `testBlockedExitReroutesToAlternativeExit` | Rerouting when one exit is blocked |
| `testNoSaferouteFallsBackToRefugePoint` | Fallback to refuge when all exits blocked |
| `testAccessibilityModeAvoidsStairRoute` | Wheelchair routing excludes stairs |

### Sample Data
The app ships with `demo_building.json` — a Campus Library floor plan with:
- 8 nodes (2 rooms, 2 intersections, 1 stairwell, 2 exits, 1 refuge point)
- 7 edges (corridors, doorways, stairs)
- 3 hazard templates for simulation

---

## Team

Built as part of an emergency evacuation system project.

| Role | Area |
|------|------|
| iOS Development | SwiftUI, Firebase integration, routing engine |
| UX/UI Design | Dark theme, emergency mode, map visualization |
| Backend | Firestore schema, Storage, real-time hazard sync |

---

## License

See [LICENSE](LICENSE) for details.
