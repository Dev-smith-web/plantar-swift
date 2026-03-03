import Foundation
import Combine

// MARK: - Perenual API Service

// MARK: - API Configuration
// The API key is read from Info.plist (key: "PerenualAPIKey").
// To set it up in Xcode: select the project → target → Info tab → add "PerenualAPIKey" with the key value.
// NEVER hardcode the key here. Ask the client to rotate sk-9fkG696d995b88f8414408 as it was previously exposed.
private let perenualAPIKey: String = {
    guard let key = Bundle.main.infoDictionary?["PerenualAPIKey"] as? String, !key.isEmpty else {
        assertionFailure("PerenualAPIKey is missing from Info.plist — add it to the target's Info tab in Xcode.")
        return ""
    }
    return key
}()

class PlantAPIService: ObservableObject {
    static let shared = PlantAPIService()

    private let apiKey = perenualAPIKey
    private let baseURL = "https://perenual.com/api/v2"

    @Published var isLoading = false
    @Published var error: String? = nil

    // Cache for API responses
    private var speciesCache: [Int: APIPlantDetail] = [:]
    private var searchCache: [String: [APIPlant]] = [:]

    // MARK: - Search Plants

    func searchPlants(query: String) async throws -> [APIPlant] {
        // Check cache first
        if let cached = searchCache[query.lowercased()] {
            return cached
        }

        let urlString = "\(baseURL)/species-list?key=\(apiKey)&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let result = try JSONDecoder().decode(APISearchResponse.self, from: data)
        searchCache[query.lowercased()] = result.data
        return result.data
    }

    // MARK: - Get Plant Details (includes hardiness map)

    func getPlantDetails(id: Int) async throws -> APIPlantDetail {
        // Check cache first
        if let cached = speciesCache[id] {
            return cached
        }

        let urlString = "\(baseURL)/species/details/\(id)?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let detail = try JSONDecoder().decode(APIPlantDetail.self, from: data)
        speciesCache[id] = detail
        return detail
    }

    // MARK: - Get All Plants (paginated)

    private var allPlantsCache: [APIPlant] = []

    func fetchAllPlants(page: Int = 1) async throws -> [APIPlant] {
        // Return cache if we have it
        if page == 1 && !allPlantsCache.isEmpty {
            return allPlantsCache
        }

        let urlString = "\(baseURL)/species-list?key=\(apiKey)&page=\(page)"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }

        let result = try JSONDecoder().decode(APISearchResponse.self, from: data)

        // Filter for plants with free images (not upgrade_access)
        let freePlants = result.data.filter { plant in
            if let imgURL = plant.defaultImage?.mediumURL ?? plant.defaultImage?.smallURL {
                return !imgURL.contains("upgrade_access")
            }
            return false
        }

        if page == 1 {
            allPlantsCache = freePlants
        }

        return freePlants
    }

    // Fetch multiple pages to get more free plants
    func fetchFreePlants(pages: Int = 3) async throws -> [APIPlant] {
        var allFreePlants: [APIPlant] = []

        for page in 1...pages {
            do {
                let plants = try await fetchAllPlants(page: page)
                allFreePlants.append(contentsOf: plants)
            } catch {
                print("Failed to fetch page \(page): \(error)")
            }
        }

        // Remove duplicates by ID
        var seen = Set<Int>()
        allFreePlants = allFreePlants.filter { plant in
            if seen.contains(plant.id) {
                return false
            }
            seen.insert(plant.id)
            return true
        }

        return allFreePlants
    }

    // MARK: - Get Plants by Common Names (for our existing database)

    func fetchImagesForPlants(_ names: [String]) async -> [String: String] {
        var imageURLs: [String: String] = [:]

        for name in names {
            do {
                let results = try await searchPlants(query: name)
                if let firstResult = results.first,
                   let imageURL = firstResult.defaultImage?.mediumURL ?? firstResult.defaultImage?.smallURL {
                    imageURLs[name.lowercased()] = imageURL
                }
            } catch {
                print("Failed to fetch image for \(name): \(error)")
            }
        }

        return imageURLs
    }
}

// MARK: - API Error

enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError: return "Server error"
        case .decodingError: return "Failed to decode response"
        case .noData: return "No data received"
        }
    }
}

// MARK: - API Response Models

struct APISearchResponse: Codable {
    let data: [APIPlant]
    let to: Int?
    let perPage: Int?
    let currentPage: Int?
    let from: Int?
    let lastPage: Int?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case data
        case to
        case perPage = "per_page"
        case currentPage = "current_page"
        case from
        case lastPage = "last_page"
        case total
    }
}

struct APIPlant: Codable, Identifiable {
    let id: Int
    let commonName: String
    let scientificName: [String]
    let otherName: [String]?
    let family: String?
    let defaultImage: APIImage?

    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case otherName = "other_name"
        case family
        case defaultImage = "default_image"
    }
}

struct APIImage: Codable {
    let license: Int?
    let licenseName: String?
    let licenseURL: String?
    let originalURL: String?
    let regularURL: String?
    let mediumURL: String?
    let smallURL: String?
    let thumbnail: String?

    enum CodingKeys: String, CodingKey {
        case license
        case licenseName = "license_name"
        case licenseURL = "license_url"
        case originalURL = "original_url"
        case regularURL = "regular_url"
        case mediumURL = "medium_url"
        case smallURL = "small_url"
        case thumbnail
    }
}

struct APIPlantDetail: Codable, Identifiable {
    let id: Int
    let commonName: String
    let scientificName: [String]
    let otherName: [String]?
    let family: String?
    let origin: [String]?
    let type: String?
    let dimension: String?
    let cycle: String?
    let watering: String?
    let sunlight: [String]?
    let pruningMonth: [String]?
    let growthRate: String?
    let droughtTolerant: Bool?
    let saltTolerant: Bool?
    let thorny: Bool?
    let invasive: Bool?
    let tropical: Bool?
    let indoor: Bool?
    let careLevel: String?
    let flowers: Bool?
    let flowerColor: String?
    let leaf: Bool?
    let leafColor: [String]?
    let poisonousToHumans: Bool?
    let poisonousToPets: Bool?
    let description: String?
    let defaultImage: APIImage?
    let hardinessLocation: APIHardinessLocation?
    let hardiness: APIHardiness?

    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case otherName = "other_name"
        case family
        case origin
        case type
        case dimension
        case cycle
        case watering
        case sunlight
        case pruningMonth = "pruning_month"
        case growthRate = "growth_rate"
        case droughtTolerant = "drought_tolerant"
        case saltTolerant = "salt_tolerant"
        case thorny
        case invasive
        case tropical
        case indoor
        case careLevel = "care_level"
        case flowers
        case flowerColor = "flower_color"
        case leaf
        case leafColor = "leaf_color"
        case poisonousToHumans = "poisonous_to_humans"
        case poisonousToPets = "poisonous_to_pets"
        case description
        case defaultImage = "default_image"
        case hardinessLocation = "hardiness_location"
        case hardiness
    }
}

struct APIHardiness: Codable {
    let min: String?
    let max: String?
}

struct APIHardinessLocation: Codable {
    let fullURL: String?
    let fullIframe: String?

    enum CodingKeys: String, CodingKey {
        case fullURL = "full_url"
        case fullIframe = "full_iframe"
    }
}
