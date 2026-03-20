import Foundation

struct AppContainer {
    let buildingRepository: BuildingPackageRepository
    let hazardStateManager: HazardStateManager
    let routingEngine: RoutingEngine

    static func makeDefault() -> AppContainer {
        let repository = BuildingPackageRepository()
        let hazardStateManager = HazardStateManager()
        let routingEngine = RoutingEngine()

        return AppContainer(
            buildingRepository: repository,
            hazardStateManager: hazardStateManager,
            routingEngine: routingEngine
        )
    }
}
