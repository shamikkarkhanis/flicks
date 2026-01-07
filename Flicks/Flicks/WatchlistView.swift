import SwiftUI
import UIKit

struct WatchlistView: View {
    private var movies: [Movie] {
        userState.watchlist.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    @EnvironmentObject var userState: UserState

    // bind scroll position to a Movie.ID
    @State private var scrollPosition: Movie.ID?
    @State private var isSearching = false
    @State private var query = ""
    @State private var selectedVibes: Set<String> = []
    @State private var selectedMovie: Movie?   // controls detail presentation

    // Dynamic background state
    @State private var backgroundGradient: LinearGradient = AppStyle.brandGradient
    @State private var currentTopMovieID: UUID?

    private let vibes = ["Cozy", "Sci-Fi", "Epic", "Feel-good", "Dark", "Romantic", "Nostalgic"] // dynamic based on user history

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 24) {
                        // main item
                        ForEach(movies) { movie in
                            movieCard(for: movie)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: MovieScrollPreferenceKey.self,
                                                value: [movie.id: geo.frame(in: .named("scrollContainer")).minY]
                                            )
                                    }
                                )
                                .onTapGesture {
                                    // Present detail for this movie
                                    selectedMovie = movie
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scrollContainer")
                .onPreferenceChange(MovieScrollPreferenceKey.self) { preferences in
                    // Find the movie closest to the top-ish area (e.g. 100pt down)
                    let targetY: CGFloat = 100
                    
                    // Filter for reasonable visibility (e.g. somewhat on screen)
                    // and find closest to target
                    if let closest = preferences.min(by: { abs($0.value - targetY) < abs($1.value - targetY) }) {
                        if closest.key != currentTopMovieID {
                            currentTopMovieID = closest.key
                            updateBackground(for: closest.key)
                        }
                    }
                }
                .background(backgroundGradient.ignoresSafeArea())
            }
        }
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(
                title: movie.title,
                subtitle: movie.subtitle,
                imageName: movie.imageName,
                friendInitials: movie.friendInitials
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func updateBackground(for movieID: UUID) {
        guard let movie = movies.first(where: { $0.id == movieID }),
              let uiImage = UIImage(named: movie.imageName),
              let colors = AppStyle.dominantColors(from: uiImage),
              let newGradient = AppStyle.gradient(from: colors)
        else { return }

        withAnimation(.linear(duration: 0.6)) {
            self.backgroundGradient = newGradient
        }
    }

    @ViewBuilder
    private func movieCard(for movie: Movie) -> some View {
        MovieCardView(
            title: movie.title,
            subtitle: movie.subtitle,
            imageName: movie.imageName,
            friendInitials: movie.friendInitials,
            dateAdded: movie.dateAdded
        )
        .id(movie.id)                               // mark as scroll target
        .onTapGesture {
            withAnimation(.snappy(duration: 0.3,  extraBounce: 0.1)) {
                scrollPosition = movie.id               // snap to this card when tapped
            }
        }
    }
}

struct MovieScrollPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] = [:]
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview {
    WatchlistView()
        .environmentObject(UserState())
}
