import SwiftUI
import UIKit

struct MovieCardMiniView: View {
    let title: String
    let dateWatched: Date
    let imageName: String
    
    @State private var backgroundGradient: LinearGradient?
    @State private var backgroundColors: [UIColor] = []
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                let dateString = DateHelpers.formatDate(dateWatched)
                Text(dateString == "Today" ? "Watched Today" : "Watched on \(dateString)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding()
        .background(
            ZStack {
                if let gradient = backgroundGradient {
                    gradient
                } else {
                    Color.gray.opacity(0.3)
                }
            }
        )
        .cornerRadius(22)
        .onAppear {
            analyzeImage()
        }
    }
    
    private func analyzeImage() {
        if imageName.hasPrefix("http"), let url = URL(string: imageName) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            extractColors(from: image)
                        }
                    }
                } catch {
                    print("Failed to load remote image for mini card: \(error)")
                }
            }
        } else if let image = UIImage(named: imageName) {
            extractColors(from: image)
        }
    }
    
    private func extractColors(from image: UIImage) {
        if backgroundColors.isEmpty {
            backgroundColors = AppStyle.dominantColors(from: image, sampleGrid: 4) ?? []
        }
        if backgroundGradient == nil, !backgroundColors.isEmpty {
            withAnimation {
                backgroundGradient = AppStyle.gradient(from: backgroundColors)
            }
        }
    }
}

#Preview {
    MovieCardMiniView(
        title: "Interstellar",
        dateWatched: Date(),
        imageName: "interstellar.jpg"
    )
    .padding()
}
