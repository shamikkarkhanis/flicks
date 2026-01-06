import SwiftUI

struct Depth3DDemoView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Interactive Parallax")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if #available(iOS 17.0, *) {
                    // The Interactive Card
                    InteractiveDepthCard(imageName: "everything.jpg")
                        .frame(width: 320, height: 480)
                        .shadow(color: .black.opacity(0.8), radius: 30, y: 20)
                } else {
                    Text("Interactive Depth requires iOS 17+")
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Text("Tilt your phone")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("We use Vision segmentation to cut out the subject and apply inverse parallax motion for a 3D effect.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    Depth3DDemoView()
}
