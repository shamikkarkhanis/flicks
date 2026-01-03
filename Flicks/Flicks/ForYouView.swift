import SwiftUI

struct ForYouView: View {
    @EnvironmentObject var userState: UserState
    
    private var movies: [Movie] {
        if !userState.recommendations.isEmpty {
            return userState.recommendations
        }
        return sampleMovies
    }

    // bind scroll position to a Movie.ID
    @State private var scrollPosition: Movie.ID?
    @State private var isSearching = false
    @State private var query = ""
    @State private var selectedVibes: Set<String> = []
    @State private var selectedMovie: Movie?   // controls detail presentation

    private let vibes = ["Cozy", "Sci-Fi", "Epic", "Feel-good", "Dark", "Romantic", "Nostalgic"] // dynamic based on user history

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 24) {
                        // main item
                        ForEach(movies) { movie in
                            movieCard(for: movie)
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
                .background(Color.white.ignoresSafeArea())
                SearchOverlay(
                    isSearching: $isSearching,
                    query: $query,
                    selectedVibes: $selectedVibes,
                    vibes: vibes
                ) {
                    // Handle search submit if needed
                }
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

    @ViewBuilder
    private func movieCard(for movie: Movie) -> some View {
        MovieCardView(
            title: movie.title,
            subtitle: movie.subtitle,
            imageName: movie.imageName,
            friendInitials: ["SK", "GJ", "CB"]
        )
        .id(movie.id)                               // mark as scroll target
        .onTapGesture {
            withAnimation(.snappy(duration: 0.3,  extraBounce: 0.1)) {
                scrollPosition = movie.id               // snap to this card when tapped
            }
        }
    }
}

#Preview {
    ForYouView()
}
