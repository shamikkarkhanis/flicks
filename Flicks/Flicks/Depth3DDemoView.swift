import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

@available(iOS 17.0, *)
struct Depth3DDemoView: View {
    let movie: Movie = sampleMovies[1] // Default to "Dune" for example
    
    @State private var originalImage: UIImage?
    @State private var foregroundImage: UIImage?
    @State private var backgroundImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    // Parallax State
    @State private var rotation: CGSize = .zero
    
    var body: some View {
        VStack {
            if isProcessing {
                ProgressView("Generating 3D Effect...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let bg = backgroundImage, let fg = foregroundImage {
                ZStack {
                    // Background Layer
                    Image(uiImage: bg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 450)
                        .blur(radius: 5) // Blur background for depth
                        .overlay(Color.black.opacity(0.3)) // Dim background
                        .offset(x: -rotation.width * 2, y: -rotation.height * 2) // Move opposite to foreground
                        .clipped()
                    
                    // Foreground Layer (The 3D Pop)
                    Image(uiImage: fg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 450)
                        .shadow(radius: 10, x: rotation.width, y: rotation.height) // Dynamic shadow
                        .offset(x: rotation.width * 5, y: rotation.height * 5) // Move with drag
                        .clipped()
                }
                .frame(width: 300, height: 450)
                .cornerRadius(20)
                .rotation3DEffect(
                    .degrees(Double(rotation.width)),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    .degrees(Double(-rotation.height)),
                    axis: (x: 1, y: 0, z: 0)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let width = value.translation.width / 10
                            let height = value.translation.height / 10
                            withAnimation(.interactiveSpring) {
                                rotation = CGSize(width: width, height: height)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring) {
                                rotation = .zero
                            }
                        }
                )
                .overlay(
                    Text("Drag to rotate 3D")
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 20),
                    alignment: .bottom
                )
            } else {
                Text("Failed to load images")
            }
        }
        .onAppear {
            loadAndProcessImage()
        }
    }
    
    private func loadAndProcessImage() {
        guard let uiImage = UIImage(named: movie.imageName) else {
            errorMessage = "Image not found: \(movie.imageName)"
            return
        }
        
        self.originalImage = uiImage
        self.isProcessing = true
        
        Task {
            do {
                let (fg, bg) = try await generateLayers(from: uiImage)
                DispatchQueue.main.async {
                    self.foregroundImage = fg
                    self.backgroundImage = bg // In a real 3D app, we'd inpaint the background
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func generateLayers(from inputImage: UIImage) async throws -> (UIImage, UIImage) {
        guard let cgImage = inputImage.cgImage else {
            throw NSError(domain: "Depth3DDemo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage"])
        }
        
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let result = request.results?.first else {
            throw NSError(domain: "Depth3DDemo", code: 2, userInfo: [NSLocalizedDescriptionKey: "No subject found"])
        }
        
        let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
        
        // Convert CVPixelBuffer (Mask) to CIImage
        let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        let originalCI = CIImage(cgImage: cgImage)
        
        // Apply Mask to get Foreground
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = originalCI
        blendFilter.backgroundImage = CIImage(color: .clear) // Transparent background
        blendFilter.maskImage = maskImage
        
        guard let foregroundCI = blendFilter.outputImage else {
            throw NSError(domain: "Depth3DDemo", code: 3, userInfo: [NSLocalizedDescriptionKey: "Filter failed"])
        }
        
        let context = CIContext()
        guard let foregroundCG = context.createCGImage(foregroundCI, from: originalCI.extent) else {
            throw NSError(domain: "Depth3DDemo", code: 4, userInfo: [NSLocalizedDescriptionKey: "Render failed"])
        }
        
        // Background is just the original (blurred later)
        // Ideally we would use inpainting to remove the subject, but simply blurring works for the effect
        return (UIImage(cgImage: foregroundCG), inputImage)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        Depth3DDemoView()
    } else {
        Text("Requires iOS 17")
    }
}
