import SwiftUI

struct MovieCardView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let friendInitials: [String]

    @State private var showDetail = false
    @State private var tapSpin = false

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.25, extraBounce: 0.05)) {
                tapSpin = true
            }
            // Present after a short delay to let the tap spin play
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                showDetail = true
                tapSpin = false
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipped()
                    .cornerRadius(20)
                    .shadow(radius: 10)

                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .cornerRadius(20)
                
                Section {
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

                    HStack(spacing: -10) {
                        ForEach(Array(friendInitials.prefix(4).enumerated()), id: \.offset) { _, initials in
                            ZStack {
                                Circle()
                                    .frame(width: 32, height: 32)
                                    .glassEffect()
                                Text(initials)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .rotation3DEffect(.degrees(tapSpin ? 8 : 0), axis: (x: 0, y: 1, z: 0), anchor: .center)
            .scaleEffect(tapSpin ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showDetail) {
            MovieDetailView(
                title: title,
                subtitle: subtitle,
                imageName: imageName,
                friendInitials: friendInitials
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

#Preview {
    MovieCardView(
        title: "Everything Everywhere All at Once",
        subtitle: "Action · Comedy · Sci‑Fi",
        imageName: "everything.jpg",
        friendInitials: []
    )
    .padding()
    .background(Color.black)
}
