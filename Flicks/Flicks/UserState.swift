import SwiftUI

class UserState: ObservableObject {
    @Published var history: [Movie] = []
    @Published var watchlist: [Movie] = []
    @Published var genres: [String] = []
    @Published var recommendations: [Movie] = []
    
    @Published var likedMovies: [Movie] = []
    @Published var neutralMovies: [Movie] = []
    @Published var dislikedMovies: [Movie] = []
    
    private var allFetchedMovies: [Movie] = []

    init() {
        for movie in history {
            // Need to persist rating state to reconstruct these lists properly if persistence was implemented
            // For now, assume history doesn't reconstruct ratings on init without persistence
            // extractGenres logic moved to addToHistory
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
    
    enum UserRating {
        case like, neutral, dislike
    }

    // Add or update a movie rating
    func addToHistory(_ movie: Movie, rating: UserRating) {
        // Ensure movie is in history
        if !history.contains(where: { $0.id == movie.id }) {
            var newMovie = movie
            newMovie.dateWatched = Date()
            history.append(newMovie)
        }
        
        // Remove from existing rating lists
        likedMovies.removeAll { $0.id == movie.id }
        neutralMovies.removeAll { $0.id == movie.id }
        dislikedMovies.removeAll { $0.id == movie.id }
        
        // Add to new rating list
        switch rating {
        case .like:
            likedMovies.append(movie)
        case .neutral:
            neutralMovies.append(movie)
        case .dislike:
            dislikedMovies.append(movie)
        }
        
        rebuildGenres()
    }
    
    // Remove a movie from the history
    func removeFromHistory(_ movie: Movie) {
        history.removeAll { $0.id == movie.id }
        likedMovies.removeAll { $0.id == movie.id }
        neutralMovies.removeAll { $0.id == movie.id }
        dislikedMovies.removeAll { $0.id == movie.id }
        
        rebuildGenres()
    }

    private func rebuildGenres() {
        var newGenres: Set<String> = []
        for movie in likedMovies {
            let list = movie.subtitle.components(separatedBy: " · ")
            for genre in list {
                let trimmed = genre.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    newGenres.insert(trimmed)
                }
            }
        }
        self.genres = Array(newGenres).sorted()
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
            
            await fetchRecommendations()
            
        } catch {
            print("Failed to sync user profile or fetch recommendations: \(error)")
        }
    }
    
    func fetchRecommendations() async {
        let name = "Shamik Karkhanis"
        do {
            // Fetch recommendations
            let dtos = try await APIService.shared.fetchRecommendations(for: name)
            let movies = dtos.map { dto in
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
            
            self.allFetchedMovies = movies
            
            await MainActor.run {
                self.recommendations = Array(movies.prefix(10))
            }
        } catch {
            print("Failed to fetch recommendations: \(error)")
        }
    }
    
    func loadMoreMovies() {
        let currentCount = recommendations.count
        guard currentCount < allFetchedMovies.count else { return }
        
        let nextBatch = allFetchedMovies.dropFirst(currentCount).prefix(10)
        recommendations.append(contentsOf: nextBatch)
    }
}
