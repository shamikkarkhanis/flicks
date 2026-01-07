import SwiftUI

class UserState: ObservableObject {
    @Published var watchlist: [Movie] = sampleMovies
    @Published var likes: [String] = []
    @Published var recommendations: [Movie] = []
    
    private var allFetchedMovies: [Movie] = []

    init() {
        for movie in watchlist {
            extractGenres(from: movie)
        }
    }
    
    // Add a movie to the watchlist if it's not already there
    func addToWatchlist(_ movie: Movie) {
        if !watchlist.contains(where: { $0.id == movie.id }) {
            watchlist.append(movie)
            extractGenres(from: movie)
        }
    }
    
    // Remove a movie from the watchlist
    func removeFromWatchlist(_ movie: Movie) {
        watchlist.removeAll { $0.id == movie.id }
    }

    private func extractGenres(from movie: Movie) {
        // Subtitle format: "Action · Comedy · Sci‑Fi"
        let genres = movie.subtitle.components(separatedBy: " · ")
        for genre in genres {
            let trimmed = genre.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !likes.contains(trimmed) {
                likes.append(trimmed)
            }
        }
    }

    func syncUserProfile() async {
        let name = "Shamik Karkhanis"
        let request = CreateUserProfileRequest(
            name: name, // Ideally this comes from a user input or auth
            genres: likes,
            movie_ids: watchlist.map { $0.tmdbId }
        )

        do {
            try await APIService.shared.createUserProfile(request: request)
            print("User profile synced successfully.")
            
            // Fetch recommendations
            let dtos = try await APIService.shared.fetchRecommendations(for: name)
            let movies = dtos.map { dto in
                Movie(
                    tmdbId: Int(dto.movie_id) ?? 0,
                    title: dto.title,
                    subtitle: dto.genres?.joined(separator: " · ") ?? "Recommended",
                    imageName: dto.backdrop_path.map { "https://image.tmdb.org/t/p/original\($0)" } ?? "",
                    friendInitials: [],
                    dateAdded: Date()
                )
            }
            
            self.allFetchedMovies = movies
            
            await MainActor.run {
                self.recommendations = Array(movies.prefix(10))
            }
            
        } catch {
            print("Failed to sync user profile or fetch recommendations: \(error)")
        }
    }
    
    func loadMoreMovies() {
        let currentCount = recommendations.count
        guard currentCount < allFetchedMovies.count else { return }
        
        let nextBatch = allFetchedMovies.dropFirst(currentCount).prefix(10)
        recommendations.append(contentsOf: nextBatch)
    }
}
