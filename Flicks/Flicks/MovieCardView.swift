import SwiftUI

struct MovieCardView: View {
    let title: String
    let subtitle: String
    let dateAdded: Date
    let imageName: String
    let friendInitials: [String]
    var disableDetail: Bool = false

    @State private var showDetail = false
    @State private var tapSpin = false

    var body: some View {
        Button {
            guard !disableDetail else { return }
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
                if imageName.hasPrefix("http"), let url = URL(string: imageName) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Color.gray
                        @unknown default:
                            Color.gray
                        }
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipped()
                    .cornerRadius(20)
                    .shadow(radius: 10)
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .clipped()
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }

                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .cornerRadius(20)
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                    }
                    .padding()

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

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(dateAdded) {
            return "Today"
        }
        
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfAdded = calendar.startOfDay(for: dateAdded)
        let components = calendar.dateComponents([.day], from: startOfAdded, to: startOfNow)
        
        if let day = components.day, day < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: dateAdded)
        }
        
        // Fallback to DateFormatter for compatibility with older SDKs
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dateAdded)
    }
}

#Preview {
    MovieCardView(
        title: "Everything Everywhere All at Once",
        subtitle: "Action · Comedy · Sci‑Fi",
        dateAdded: Date(),
        imageName: "everything.jpg",
        friendInitials: ["SK", "FG"]
    )
    .padding()
    .background(Color.black)
}
