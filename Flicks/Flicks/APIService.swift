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
    private let baseURL = "http://127.0.0.1:8000"

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
}

struct MovieDTO: Codable {
    let movie_id: String
    let title: String
    let genres: [String]?
    let score: Double?
    let backdrop_path: String?
}
