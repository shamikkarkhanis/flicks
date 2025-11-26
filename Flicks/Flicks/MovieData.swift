import SwiftUI

struct Movie: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let friendInitials: [String]
}

// Centralized sample data for the app
let sampleMovies: [Movie] = [
    Movie(
        title: "Everything Everywhere All at Once",
        subtitle: "Action · Comedy · Sci‑Fi",
        imageName: "everything.jpg",
        friendInitials: ["SJ", "AM", "KL", "R"]
    ),
    Movie(
        title: "Dune: Part Two",
        subtitle: "Adventure · Drama · Sci‑Fi",
        imageName: "dune.jpg",
        friendInitials: ["MK", "JP"]
    ),
    Movie(
        title: "Star Wars: Part 4",
        subtitle: "Adventure · Drama · Sci‑Fi",
        imageName: "star.jpg",
        friendInitials: ["MK", "JP", "NL"]
    ),
    Movie(
        title: "Iron Man 1",
        subtitle: "Action · Adventure · Sci‑Fi",
        imageName: "iron.jpg",
        friendInitials: ["MK"]
    ),
    Movie(
        title: "Indiana Jones: Raiders of the Lost Ark",
        subtitle: "Adventure · Action · Classic",
        imageName: "indiana.jpg",
        friendInitials: ["KC", "JP"]
    ),
    Movie(
        title: "Heretic",
        subtitle: "Thriller · Mystery",
        imageName: "heretic.jpg",
        friendInitials: ["BL", "HL", "OH"]
    ),

    // Added 5 more movies
    Movie(
        title: "The Matrix",
        subtitle: "Action · Sci‑Fi",
        imageName: "matrix.jpg",
        friendInitials: ["SJ", "TR"]
    ),
    Movie(
        title: "Interstellar",
        subtitle: "Adventure · Drama · Sci‑Fi",
        imageName: "interstellar.jpg",
        friendInitials: ["AM", "KL", "JP"]
    ),
    Movie(
        title: "The Dark Knight",
        subtitle: "Action · Crime · Drama",
        imageName: "darkknight.jpg",
        friendInitials: ["MK", "NL"]
    ),
    Movie(
        title: "La La Land",
        subtitle: "Romance · Drama · Music",
        imageName: "lalaland.jpg",
        friendInitials: ["KC", "OH"]
    ),
    Movie(
        title: "Spider‑Man: Into the Spider‑Verse",
        subtitle: "Animation · Action · Adventure",
        imageName: "spiderverse.jpg",
        friendInitials: ["BL", "SJ", "AM"]
    )
]
