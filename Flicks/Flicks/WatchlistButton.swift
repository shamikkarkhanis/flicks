import SwiftUI

struct WatchlistButton: View {
    @Binding var isAdded: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAdded.toggle()
            }
            if isAdded {
                action()
            }
        }) {
            ZStack {
                Image(systemName: isAdded ? "checkmark" : "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 50, height: 50)
            .glassEffect()
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .contentShape(Circle())
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        WatchlistButton(isAdded: .constant(false), action: {})
    }
}
