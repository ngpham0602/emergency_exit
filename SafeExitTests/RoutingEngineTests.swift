import XCTest
@testable import SafeExit

final class RoutingEngineTests: XCTestCase {
    private var building: BuildingPackage!
    private var engine: RoutingEngine!

    override func setUpWithError() throws {
        engine = RoutingEngine()
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(bundle.url(forResource: "demo_building", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        building = try decoder.decode(BuildingPackage.self, from: data)
    }

    func testNormalRouteFindsAvailableExit() throws {
        let route = try engine.computeRoute(
            in: building,
            startNodeID: "room-a101",
            activeHazards: [],
            accessibilityMode: false
        )

        XCTAssertEqual(route.destinationKind, .exit)
        XCTAssertEqual(route.destinationNode.id, "exit-main")
    }

    func testBlockedExitReroutesToAlternativeExit() throws {
        let hazards = building.hazardTemplates.filter { $0.id == "hazard-side-exit-blocked" }
        let route = try engine.computeRoute(
            in: building,
            startNodeID: "room-a101",
            activeHazards: hazards,
            accessibilityMode: false
        )

        XCTAssertEqual(route.destinationNode.id, "exit-main")
    }

    func testNoSafeExitFallsBackToRefugePoint() throws {
        let hazards = building.hazardTemplates.filter {
            ["hazard-main-exit-blocked", "hazard-side-exit-blocked"].contains($0.id)
        }
        let route = try engine.computeRoute(
            in: building,
            startNodeID: "room-a101",
            activeHazards: hazards,
            accessibilityMode: false
        )

        XCTAssertEqual(route.destinationKind, .refugePoint)
        XCTAssertEqual(route.destinationNode.id, "refuge-west")
    }

    func testAccessibilityModeAvoidsStairRoute() throws {
        let route = try engine.computeRoute(
            in: building,
            startNodeID: "room-a101",
            activeHazards: [],
            accessibilityMode: true
        )

        XCTAssertEqual(route.destinationNode.id, "exit-main")
        XCTAssertFalse(route.path.contains(where: { $0.type == .stairwell }))
    }
}
