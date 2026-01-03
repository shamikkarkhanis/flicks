import SwiftUI

struct Movie: Identifiable, Hashable {
    let id = UUID()
    let tmdbId: Int
    let title: String
    let subtitle: String
    let imageName: String
    let friendInitials: [String]
}

// Centralized sample data for the app
let sampleMovies: [Movie] = [
    Movie(
        tmdbId: 545609,
        title: "Everything Everywhere All at Once",
        subtitle: "Action · Comedy · Sci‑Fi",
        imageName: "everything.jpg",
        friendInitials: ["SJ", "AM", "KL", "R"]
    ),
    Movie(
        tmdbId: 693134,
        title: "Dune: Part Two",
        subtitle: "Adventure · Drama · Sci‑Fi",
        imageName: "dune.jpg",
        friendInitials: ["MK", "JP"]
    ),
    Movie(
        tmdbId: 11,
        title: "Star Wars: Part 4",
        subtitle: "Adventure · Drama · Sci‑Fi",
        imageName: "star.jpg",
        friendInitials: ["MK", "JP", "NL"]
    ),
    Movie(
        tmdbId: 1726,
        title: "Iron Man 1",
        subtitle: "Action · Adventure · Sci‑Fi",
        imageName: "iron.jpg",
        friendInitials: ["MK"]
    ),
    Movie(
        tmdbId: 827,
        title: "Indiana Jones: Raiders of the Lost Ark",
        subtitle: "Adventure · Action · Classic",
        imageName: "indiana.jpg",
        friendInitials: ["KC", "JP"]
    ),
    Movie(
        tmdbId: 1076200,
        title: "Heretic",
        subtitle: "Thriller · Mystery",
        imageName: "heretic.jpg",
        friendInitials: ["BL", "HL", "OH"]
    ),

    // Added 5 more movies
    Movie(
        tmdbId: 603,
        title: "The Matrix",
        subtitle: "Action · Sci‑Fi",
        imageName: "matrix.jpg",
        friendInitials: ["SJ", "TR"]
    ),
    Movie(
        tmdbId: 157336,
        title: "Interstellar",
        subtitle: "Adventure · Drama · Sci‑Fi",
        imageName: "interstellar.jpg",
        friendInitials: ["AM", "KL", "JP"]
    ),
    Movie(
        tmdbId: 155,
        title: "The Dark Knight",
        subtitle: "Action · Crime · Drama",
        imageName: "darkknight.jpg",
        friendInitials: ["MK", "NL"]
    ),
    Movie(
        tmdbId: 313369,
        title: "La La Land",
        subtitle: "Romance · Drama · Music",
        imageName: "lalaland.jpg",
        friendInitials: ["KC", "OH"]
    ),
    Movie(
        tmdbId: 324857,
        title: "Spider‑Man: Into the Spider‑Verse",
        subtitle: "Animation · Action · Adventure",
        imageName: "spiderverse.jpg",
        friendInitials: ["BL", "SJ", "AM"]
    )
]
