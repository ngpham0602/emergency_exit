import Foundation

struct BuildingPackageRepository {
    func loadSamplePackage(bundle: Bundle = .main) throws -> BuildingPackage {
        guard let url = bundle.url(forResource: "demo_building", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BuildingPackage.self, from: data)
    }
}
