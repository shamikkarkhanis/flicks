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
            ZStack(alignment: .top) {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                            let prevMovie = movies.indices.contains(index - 1) ? movies[index - 1] : nil
                            let nextMovie = movies.indices.contains(index + 1) ? movies[index + 1] : nil
                            
                            movieCard(for: movie, prevImage: prevMovie?.imageName, nextImage: nextMovie?.imageName)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .onTapGesture {
                                    selectedMovie = movie
                                }
                                .onAppear {
                                    if movie.id == movies.last?.id {
                                        userState.loadMoreMovies()
                                    }
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .ignoresSafeArea()
                .background(.black)
                
                // "For You" Indicator
                VStack {
                    
                    Spacer()
                    
                    Text("For You")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .glassEffect()
                    
                }
                
//                SearchOverlay(
//                    isSearching: $isSearching,
//                    query: $query,
//                    selectedVibes: $selectedVibes,
//                    vibes: vibes
//                ) {
//                    // Handle search submit if needed
//                }
            }
        }
        .sheet(item: $selectedMovie) { movie in
            MovieDetailView(
                title: movie.title,
                subtitle: movie.subtitle,
                imageName: movie.imageName,
                friendInitials: movie.friendInitials
            )
            .presentationDetents([.large, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func movieCard(for movie: Movie, prevImage: String?, nextImage: String?) -> some View {
        GeometryReader { proxy in
            VerticalMovieCardView(
                title: movie.title,
                subtitle: movie.subtitle,
                imageName: movie.imageName,
                prevImageName: prevImage,
                nextImageName: nextImage,
                friendInitials: ["SK", "GJ", "CB"],
                disableDetail: false,
                dynamicFeathering: true,
                enableDepthEffect: true,
                cardWidth: proxy.size.width,
                cardHeight: proxy.size.height,
                enableSwipe: false,
                cornerRadius: 0
            )
        }
        .id(movie.id)
    }
}

#Preview {
    ForYouView()
        .environmentObject(UserState())
}
