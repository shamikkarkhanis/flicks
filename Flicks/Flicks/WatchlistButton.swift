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
            .frame(width: 56, height: 56)
            .glassEffect()
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        WatchlistButton(isAdded: .constant(false), action: {})
    }
}
