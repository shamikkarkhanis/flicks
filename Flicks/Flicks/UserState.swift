import SwiftUI

class UserState: ObservableObject {
    @Published var history: [Movie] = []
    @Published var watchlist: [Movie] = []
    @Published var genres: [String] = []
    @Published var recommendations: [Movie] = []
    
    private var allFetchedMovies: [Movie] = []

    init() {
        for movie in history {
            extractGenres(from: movie)
        }
    }
    
    func addToWatchlist(_ movie: Movie) {
        if !watchlist.contains(where: { $0.id == movie.id }) {
            var newMovie = movie
            newMovie.dateAdded = Date()
            watchlist.append(newMovie)
        }
    }

    func removeFromWatchlist(_ movie: Movie) {
        watchlist.removeAll { $0.id == movie.id }
    }
    
    // Add a movie to the history if it's not already there
    func addToHistory(_ movie: Movie, withGenres: Bool = true) {
        if !history.contains(where: { $0.id == movie.id }) {
            var newMovie = movie
            newMovie.dateWatched = Date()
            history.append(newMovie)
            if withGenres {
                extractGenres(from: newMovie)
            }
        }
    }
    
    // Remove a movie from the history
    func removeFromHistory(_ movie: Movie) {
        history.removeAll { $0.id == movie.id }
    }

    private func extractGenres(from movie: Movie) {
        // Subtitle format: "Action · Comedy · Sci‑Fi"
        let genresList = movie.subtitle.components(separatedBy: " · ")
        for genre in genresList {
            let trimmed = genre.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !genres.contains(trimmed) {
                genres.append(trimmed)
            }
        }
    }

    func syncUserProfile() async {
        let name = "Shamik Karkhanis"
        let request = CreateUserProfileRequest(
            name: name, // Ideally this comes from a user input or auth
            genres: genres,
            movie_ids: history.map { $0.tmdbId }
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
