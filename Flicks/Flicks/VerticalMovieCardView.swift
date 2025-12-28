import SwiftUI

struct VerticalMovieCardView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let friendInitials: [String]
    var disableDetail: Bool = true

    // Callback the parent can provide to remove this card from a deck
    var onRemove: (() -> Void)? = nil

    @State private var showDetail = false
    @State private var tapSpin = false
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var isHidden = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .cornerRadius(30)

            Rectangle()
                .fill(color.opacity(0.2))
                .cornerRadius(30)

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding()
            }
        }
        .opacity(isHidden ? 0 : 1)
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
    }
    
    func swipeCard(width: CGFloat) {
        switch width {
        case -500...(-150): // Swipe left
            offset = CGSize(width: -500, height: 0)
            commitRemoval()
        case 150...500: // Swipe right
            offset = CGSize(width: 500, height: 0)
            commitRemoval()
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

    private func commitRemoval() {
        // If parent provided a remover, call it after the fly-out animation.
        if let onRemove {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                onRemove()
            }
        } else {
            // Fallback: locally hide the view so it disappears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.15)) {
                    isHidden = true
                }
            }
        }
    }
}

#Preview {
    VerticalMovieCardView(
        title: "Everything Everywhere All at Once",
        subtitle: "Action · Comedy · Sci‑Fi",
        imageName: "everything.jpg",
        friendInitials: []
    )
    .padding()
    .background(Color.black)
}
