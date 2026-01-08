import SwiftUI

struct WatchlistButton: View {
    @Binding var isAdded: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            ZStack {
                Image(systemName: isAdded ? "star.fill" : "star")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 50, height: 50)
            .glassEffect()
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .overlay(
            Color.clear
                .frame(width: 80, height: 80)
                .contentShape(Circle())
                .onTapGesture(perform: toggle)
        )
        .buttonStyle(.plain)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isAdded.toggle()
        }
        if isAdded {
            action()
        }
    }
}

#Preview {
    ZStack {
        WatchlistButton(isAdded: .constant(false), action: {})
    }
}
