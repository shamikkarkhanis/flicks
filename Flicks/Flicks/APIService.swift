import Foundation

struct CreateUserProfileRequest: Codable {
    let name: String
    let genres: [String]
    let movie_ids: [Int]
}

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int)
}

class APIService {
    static let shared = APIService()
    private let baseURL = "http://192.168.4.97:8000"

    private init() {}

    func createUserProfile(request: CreateUserProfileRequest) async throws {
        guard let url = URL(string: "\(baseURL)/encode") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
        } catch {
            throw APIError.decodingError(error)
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // Convenience method for domain objects
    func createProfile(name: String, genres: [String], movies: [Movie]) async throws {
        let request = CreateUserProfileRequest(
            name: name,
            genres: genres,
            movie_ids: movies.map { $0.tmdbId }
        )
        try await createUserProfile(request: request)
    }

    // Alias for updating profile (same endpoint)
    func updateProfile(name: String, genres: [String], movies: [Movie]) async throws {
        try await createProfile(name: name, genres: genres, movies: movies)
    }

    func fetchRecommendations(for userId: String) async throws -> [MovieDTO] {
        guard let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/users/\(encodedUserId)/recommendations") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw APIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let movies = try JSONDecoder().decode([MovieDTO].self, from: data)
            return movies
        } catch {
            print("Decoding error or network error: \(error)")
            throw error
        }
    }
    
    // Convenience method for domain objects
    func getRecommendations(for userId: String) async throws -> [Movie] {
        let dtos = try await fetchRecommendations(for: userId)
        return dtos.map { dto in
            Movie(
                tmdbId: Int(dto.movie_id) ?? 0,
                title: dto.title,
                subtitle: dto.genres?.joined(separator: " · ") ?? "Recommended",
                imageName: dto.backdrop_path.map { "https://image.tmdb.org/t/p/original\($0)" } ?? "",
                friendInitials: [],
                dateAdded: Date(),
                dateWatched: Date()
            )
        }
    }
    func fetchUserProfile(for userId: String) async throws -> [UserProfileDTO] {
        guard let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/users/\(encodedUserId)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([UserProfileDTO].self, from: data)
    }
}

struct MovieDTO: Codable {
    let movie_id: String
    let title: String
    let genres: [String]?
    let score: Double?
    let backdrop_path: String?
}

struct UserProfileDTO: Codable {
    let name: String
    let genres: [String]
    let movie_ids: [Int]
    let data: UserDataDTO
}

struct UserDataDTO: Codable {
    let liked: [Int]
    let disliked: [Int]
    let neutral: [Int]
    let watchlist: [Int]
    let history: [Int]
}
