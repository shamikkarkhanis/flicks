import SwiftUI
import UIKit

struct VerticalMovieCardView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let prevImageName: String? // To blend top edge
    let nextImageName: String? // To blend bottom edge
    let friendInitials: [String]
    var disableDetail: Bool = true
    var dynamicFeathering: Bool = false

    // Callback the parent can provide to remove this card from a deck
    // true = liked (right swipe), false = passed (left swipe)
    var onSwipe: ((Bool) -> Void)? = nil

    @State private var showDetail = false
    @State private var tapSpin = false
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var isHidden = false
    
    @State private var topColor: Color = .black
    @State private var bottomColor: Color = .black

    // Provide width and height for the card’s frame
    var cardWidth: CGFloat = 400
    var cardHeight: CGFloat = 600
    var enableSwipe: Bool = true
    var cornerRadius: CGFloat = 30
    
    var body: some View {
        let content = ZStack(alignment: .topLeading) {
            // Background for dynamic feathering
            if dynamicFeathering {
                LinearGradient(
                    colors: [topColor, bottomColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            
            Group {
                if imageName.hasPrefix("http"), let url = URL(string: imageName) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: cardWidth, height: cardHeight, alignment: .center)
                        } else {
                            Color.gray
                                .frame(width: cardWidth, height: cardHeight)
                        }
                    }
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: cardWidth, height: cardHeight, alignment: .center)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            Rectangle()
                .fill(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            
            // Gradient for text readability at the top
            LinearGradient(
                colors: [.black.opacity(0.7), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // Gradient for text readability at the bottom
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            VStack(alignment: .trailing, spacing: 0) {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                }
                .padding()
                .padding(.bottom, 60) // Extra padding for the bottom area
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .opacity(isHidden ? 0 : 1)
        .frame(width: cardWidth, height: cardHeight) // ensure overlays match image bounds
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

        if enableSwipe {
            content
                .offset(x: offset.width * 0.4, y: offset.height * 0.4)
                .rotationEffect(.degrees(Double(offset.width / 40)))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation
                            withAnimation {
                                changeColor(width: offset.width)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                swipeCard(width: gesture.translation.width)
                                changeColor(width: offset.width)
                            }
                        }
                )
        } else {
            content
        }
    }
    
    func swipeCard(width: CGFloat) {
        switch width {
        case -500...(-150): // Swipe left
            offset = CGSize(width: -500, height: 0)
            commitRemoval(liked: false)
        case 150...500: // Swipe right
            offset = CGSize(width: 500, height: 0)
            commitRemoval(liked: true)
        default:
            // Not far enough: snap back
            offset = .zero
        }
    }
    
    func changeColor(width: CGFloat) {
        switch width {
        case -500...(-150): // Swipe left
            color = .red
        case 150...500: // Swipe right
            color = .green
        default:
            // Not far enough: snap back
            color = .black
        }
    }

    private func commitRemoval(liked: Bool) {
        if let onSwipe {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                onSwipe(liked)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHidden = true
                }
            }
        }
    }
}

#Preview {
    GeometryReader { proxy in
        VerticalMovieCardView(
            title: "Everything Everywhere All at Once",
            subtitle: "Action · Comedy · Sci‑Fi",
            imageName: "everything.jpg",
            prevImageName: nil,
            nextImageName: nil,
            friendInitials: [],
            cardWidth: proxy.size.width,
            cardHeight: proxy.size.height,
            enableSwipe: false,
            cornerRadius: 0
        )
    }
    .ignoresSafeArea()
}
