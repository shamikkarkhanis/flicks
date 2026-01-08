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
        
        do {
            // 1. Upload Profile
            try await APIService.shared.createProfile(name: name, genres: genres, movies: history)
            print("User profile created successfully.")
            
            // 2. Fetch Fresh Recommendations
            await fetchRecommendations()
            
        } catch {
            print("Failed to sync user profile: \(error)")
        }
    }
    
    func updateUserProfile() async {
        let name = "Shamik Karkhanis"
        
        do {
            // 1. Update Profile (Encode)
            try await APIService.shared.updateProfile(name: name, genres: genres, movies: history)
            print("User profile updated successfully.")
            
            // 2. Fetch Fresh Recommendations
            await fetchRecommendations()
            
        } catch {
            print("Failed to update user profile: \(error)")
        }
    }
    
    func fetchRecommendations() async {
        let name = "Shamik Karkhanis"
        do {
            let movies = try await APIService.shared.getRecommendations(for: name)
            
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
