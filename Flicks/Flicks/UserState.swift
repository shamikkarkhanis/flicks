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
    private let currentUserId = "Shamik Karkhanis"
    private var ratingSessionCount = 0
    private var shownMovieIds: Set<Int> = []

    init() {
        // Hydration logic would go here in a real app
    }
    
    // MARK: - Watchlist Management
    
    func addToWatchlist(_ movie: Movie) {
        // Optimistic UI Update
        if !watchlist.contains(where: { $0.id == movie.id }) {
            var newMovie = movie
            newMovie.dateAdded = Date()
            watchlist.append(newMovie)
        }
        
        // Background API Call
        Task {
            do {
                try await APIService.shared.addToWatchlist(userId: currentUserId, movieId: movie.tmdbId)
                print("Added to watchlist on backend: \(movie.title)")
            } catch {
                print("Failed to add to watchlist backend: \(error)")
                // Optionally revert UI here
            }
        }
    }

    func removeFromWatchlist(_ movie: Movie) {
        // Optimistic UI Update
        watchlist.removeAll { $0.id == movie.id }
        
        // Background API Call
        Task {
            do {
                try await APIService.shared.removeFromWatchlist(userId: currentUserId, movieId: movie.tmdbId)
                print("Removed from watchlist on backend: \(movie.title)")
            } catch {
                print("Failed to remove from watchlist backend: \(error)")
            }
        }
    }
    
    // MARK: - Rating & History
    
    enum UserRating {
        case like, neutral, dislike
        
        var apiString: String {
            switch self {
            case .like: return "like"
            case .neutral: return "neutral"
            case .dislike: return "dislike"
            }
        }
    }

    func addToHistory(_ movie: Movie, rating: UserRating) async {
        // 1. Optimistic UI Updates
        // Execute on MainActor to ensure UI updates are safe since this is now async
        await MainActor.run {
            if !history.contains(where: { $0.id == movie.id }) {
                var newMovie = movie
                newMovie.dateWatched = Date()
                history.append(newMovie)
            }
            
            likedMovies.removeAll { $0.id == movie.id }
            neutralMovies.removeAll { $0.id == movie.id }
            dislikedMovies.removeAll { $0.id == movie.id }
            
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
        
        // 2. Background Sync & "Live" Refill
        do {
            print("[LiveRecs] Sending rating for '\(movie.title)' as \(rating.apiString)...")
            // Send rating to backend
            try await APIService.shared.rateMovie(userId: currentUserId, movieId: movie.tmdbId, rating: rating.apiString)
            print("[LiveRecs] Successfully rated '\(movie.title)' on backend.")
            
            ratingSessionCount += 1
            
            // Fetch fresh recommendations every 3 ratings to keep the feed alive
            if ratingSessionCount % 3 == 0 {
                print("[LiveRecs] Triggering refill fetch (Session count: \(ratingSessionCount))...")
                await fetchRecommendations(isLiveRefill: true)
            }
        } catch {
            print("[LiveRecs] Failed to sync rating or fetch live recs: \(error)")
        }
    }
    
    func removeFromHistory(_ movie: Movie) {
        history.removeAll { $0.id == movie.id }
        likedMovies.removeAll { $0.id == movie.id }
        neutralMovies.removeAll { $0.id == movie.id }
        dislikedMovies.removeAll { $0.id == movie.id }
        
        rebuildGenres()
    }

    /// Used during onboarding to accumulate picks locally without triggering API calls or live refills.
    func addPickDuringOnboarding(_ movie: Movie) {
        if !history.contains(where: { $0.id == movie.id }) {
            var newMovie = movie
            newMovie.dateWatched = Date()
            history.append(newMovie)
        }
        
        if !likedMovies.contains(where: { $0.id == movie.id }) {
            likedMovies.append(movie)
        }
        
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

    // MARK: - Profile Sync & Recommendations

    func syncUserProfile() async {
        do {
            print("[LiveRecs] Performing bulk profile sync...")
            // 1. Upload the entire local state to create/reset the profile on the backend
            try await APIService.shared.createProfile(name: currentUserId, genres: genres, movies: history)
            print("[LiveRecs] Profile bulk sync successful.")
            
            // 2. Fetch fresh recommendations based on the new profile
            await fetchRecommendations()
        } catch {
            print("[LiveRecs] Failed to sync user profile: \(error)")
        }
    }
    
    func fetchRecommendations(isLiveRefill: Bool = false) async {
        print("[LiveRecs] Fetching recommendations (Live Refill: \(isLiveRefill))...")
        do {
            let fetchedMovies = try await APIService.shared.getRecommendations(for: currentUserId)
            
            await MainActor.run {
                if isLiveRefill {
                    print("[LiveRecs] Received \(fetchedMovies.count) candidates.")
                    // Smart Deduplication:
                    // 1. Filter out movies the user has already seen/rated/watchlisted locally
                    // 2. Filter out movies already in the current recommendations list
                    let existingIds = Set(
                        history.map { $0.tmdbId } +
                        watchlist.map { $0.tmdbId } +
                        recommendations.map { $0.tmdbId }
                    )
                    
                    let newUniqueMovies = fetchedMovies.filter { !existingIds.contains($0.tmdbId) }
                    let duplicateCount = fetchedMovies.count - newUniqueMovies.count
                    print("[LiveRecs] Deduped \(duplicateCount) movies (already seen/listed).")
                    
                    if !newUniqueMovies.isEmpty {
                        print("[LiveRecs] Added \(newUniqueMovies.count) new unique movies.")
                        // Append to the end of the active list
                        self.recommendations.append(contentsOf: newUniqueMovies)
                        self.allFetchedMovies.append(contentsOf: newUniqueMovies)
                    } else {
                        print("[LiveRecs] No new unique movies found to add.")
                    }
                    
                } else {
                    // Fresh Load (Replace)
                    print("[LiveRecs] Fresh load complete. Replaced list with \(fetchedMovies.count) movies.")
                    self.allFetchedMovies = fetchedMovies
                    self.recommendations = Array(fetchedMovies.prefix(10))
                    
                    // Track initial movies as shown
                    self.shownMovieIds.formUnion(self.recommendations.map { $0.tmdbId })
                }
            }
        } catch {
            print("[LiveRecs] Failed to fetch recommendations: \(error)")
        }
    }
    
    func loadMoreMovies() {
        let currentCount = recommendations.count
        
        // If we are running low on buffered movies (less than 5 unseen left), sync and fetch more
        if allFetchedMovies.count - currentCount < 5 {
             print("[LiveRecs] Buffer low (\(allFetchedMovies.count - currentCount) left). Syncing and fetching more...")
             Task {
                 do {
                     // 1. Sync shown movies AND current buffer to backend
                     // We include current recommendations to prevent the backend from suggesting what we already have
                     let bufferIds = Set(recommendations.map { $0.tmdbId })
                     let allIdsToExclude = shownMovieIds.union(bufferIds)
                     
                     if !allIdsToExclude.isEmpty {
                         print("[LiveRecs] Syncing \(allIdsToExclude.count) IDs (shown + buffered) to exclude...")
                         try await APIService.shared.syncShownMovies(userId: currentUserId, movieIds: Array(allIdsToExclude))
                         shownMovieIds.removeAll()
                     }
                     
                     // 2. Then fetch fresh ones (backend will now exclude everything we have)
                     await fetchRecommendations(isLiveRefill: true)
                 } catch {
                     print("[LiveRecs] Sync/Fetch failed: \(error)")
                 }
             }
        }
        
        guard currentCount < allFetchedMovies.count else { return }
        
        let nextBatch = allFetchedMovies.dropFirst(currentCount).prefix(10)
        recommendations.append(contentsOf: nextBatch)
        
        // Track these newly added movies as shown
        shownMovieIds.formUnion(nextBatch.map { $0.tmdbId })
    }
}
