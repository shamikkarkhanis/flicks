import SwiftUI
import CoreMotion
import Vision
import CoreImage.CIFilterBuiltins

// MARK: - 1. The View (UI Layer)
@available(iOS 17.0, *)
struct InteractiveDepthCard: View {
    let imageName: String
    
    // State
    @StateObject private var motion = ParallaxMotionManager()
    @State private var foregroundImage: UIImage?
    @State private var backgroundImage: UIImage?
    @State private var faceRect: CGRect?
    @State private var saliencyRect: CGRect?
    @State private var isLoading = true
    
    // Configuration
    private let parallaxIntensity: CGFloat = 30.0 // How much it moves
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let bg = backgroundImage, let fg = foregroundImage {
                    // Smart Framing Calculation
                    // If face, zoom 1.5. If saliency, zoom 1.35. Else 1.1.
                    let smartScale: CGFloat = faceRect != nil ? 1.5 : (saliencyRect != nil ? 1.35 : 1.1)
                    let smartOffset: CGSize = calculateSmartOffset(proxy: proxy, scale: smartScale)
                    
                    ZStack {
                        // Layer 1: Background (The World)
                        // We scale it up slightly so edges don't show when tilting
                        Image(uiImage: bg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width + 40, height: proxy.size.height + 40)
                            .blur(radius: 5) // Depth of field effect
                            .offset(
                                x: motion.roll * (parallaxIntensity * 0.5), // Background moves slightly in direction of tilt
                                y: motion.pitch * (parallaxIntensity * 0.5)
                            )
                        
                        // Layer 2: Foreground (The Hero)
                        Image(uiImage: fg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .shadow(color: .black.opacity(0.5), radius: 15, x: -motion.roll * 10, y: -motion.pitch * 10) // Dynamic shadow
                            .offset(
                                x: -motion.roll * parallaxIntensity, // Foreground moves OPPOSITE to background
                                y: -motion.pitch * parallaxIntensity
                            )
                    }
                    .scaleEffect(smartScale)
                    .offset(smartOffset)
                } else {
                    // Loading State
                    ZStack {
                        if let original = UIImage(named: imageName) {
                            Image(uiImage: original)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.3)
                        }
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onAppear {
                processImage()
                motion.startUpdates()
            }
            .onDisappear {
                motion.stopUpdates()
            }
        }
    }
    
    private func calculateSmartOffset(proxy: GeometryProxy, scale: CGFloat) -> CGSize {
        // Prioritize face, then saliency
        let subjectRect = faceRect ?? saliencyRect
        guard let subject = subjectRect else { return .zero }
        
        let isFace = faceRect != nil
        
        // 1. Calculate Subject Center in Normalized Coordinates (0...1)
        // Vision origin is Bottom-Left. SwiftUI is Top-Left.
        let subjectCenterX = subject.midX
        let subjectCenterY_Vision = subject.midY
        let subjectCenterY_SwiftUI = 1.0 - subjectCenterY_Vision
        
        // 2. Define Target Position (Where we want the center to be)
        // Face: Horizontal Center (0.5), Top Third (0.35)
        // Object: Horizontal Center (0.5), Dead Center (0.5)
        let targetX: CGFloat = 0.5
        let targetY: CGFloat = isFace ? 0.35 : 0.5
        
        // 3. Calculate the Shift needed in Normalized space
        let deltaX = targetX - subjectCenterX
        let deltaY = targetY - subjectCenterY_SwiftUI
        
        // 4. Convert to Points (View Dimensions)
        // We multiply by the scaled size because we are moving the *scaled* image
        let moveX = deltaX * proxy.size.width * scale
        let moveY = deltaY * proxy.size.height * scale
        
        return CGSize(width: moveX, height: moveY)
    }
    
    private func processImage() {
        guard let input = UIImage(named: imageName) else { return }
        
        Task {
            do {
                // Use our helper to split the image
                let result = try await ImageDepthSplitter.split(image: input)
                
                withAnimation(.easeOut(duration: 0.8)) {
                    self.foregroundImage = result.foreground
                    self.backgroundImage = result.background
                    self.faceRect = result.faceRect
                    self.saliencyRect = result.saliencyRect
                    self.isLoading = false
                }
            } catch {
                print("Error splitting image: \(error)")
            }
        }
    }
}

// MARK: - 2. The Engine (Core Motion)
class ParallaxMotionManager: ObservableObject {
    private let manager = CMMotionManager()
    
    // Published values for the UI to observe (-1.0 to 1.0 range usually)
    @Published var pitch: Double = 0.0 // Up/Down
    @Published var roll: Double = 0.0  // Left/Right
    
    func startUpdates() {
        guard manager.isDeviceMotionAvailable else { return }
        
        manager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60 FPS
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            
            // Interactive Spring interpolation could be added here for smoothness
            // For now, we use raw clamped values
            withAnimation(.linear(duration: 0.1)) {
                self.pitch = data.attitude.pitch.clamped(to: -0.5...0.5)
                self.roll = data.attitude.roll.clamped(to: -0.5...0.5)
            }
        }
    }
    
    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
    }
}

// MARK: - 3. The Brains (Vision Framework)
@available(iOS 17.0, *)
struct ImageDepthSplitter {
    
    struct Result {
        let foreground: UIImage
        let background: UIImage
        let faceRect: CGRect? // Normalized (0...1)
        let saliencyRect: CGRect? // Fallback if no face
    }
    
    static func split(image: UIImage) async throws -> Result {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "ImageError", code: 0, userInfo: nil)
        }
        
        // 1. Create the Vision Requests
        let segmentationRequest = VNGenerateForegroundInstanceMaskRequest()
        let faceRequest = VNDetectFaceRectanglesRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 2. Perform the requests
        try handler.perform([segmentationRequest, faceRequest, saliencyRequest])
        
        // 3. Handle Segmentation
        guard let segResult = segmentationRequest.results?.first else {
            throw NSError(domain: "VisionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No subject found"])
        }
        
        let maskBuffer = try segResult.generateScaledMaskForImage(forInstances: segResult.allInstances, from: handler)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let originalCI = CIImage(cgImage: cgImage)
        
        // 4. Create Foreground (Apply Mask)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = originalCI
        blendFilter.backgroundImage = CIImage(color: CIColor.clear)
        blendFilter.maskImage = maskImage
        
        guard let fgOutput = blendFilter.outputImage else { throw NSError(domain: "FilterError", code: 0) }
        
        // 5. Create Background
        let bgOutput = originalCI
            .applyingGaussianBlur(sigma: 5.0)
            .clampedToExtent()
        
        // 6. Convert back to UIImage
        let context = CIContext()
        guard let fgRef = context.createCGImage(fgOutput, from: originalCI.extent),
              let bgRef = context.createCGImage(bgOutput, from: originalCI.extent) else {
            throw NSError(domain: "RenderError", code: 0)
        }
        
        // 7. Handle Face Detection
        let faceRect = faceRequest.results?.first?.boundingBox
        
        // 8. Handle Saliency (Fallback)
        var saliencyRect: CGRect?
        if let saliencyObservation = saliencyRequest.results?.first,
           let salientObjects = saliencyObservation.salientObjects,
           let firstObject = salientObjects.first {
            saliencyRect = firstObject.boundingBox
        }
        
        return Result(
            foreground: UIImage(cgImage: fgRef),
            background: UIImage(cgImage: bgRef),
            faceRect: faceRect,
            saliencyRect: saliencyRect
        )
    }
}

// MARK: - Helpers
extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        if #available(iOS 17.0, *) {
            InteractiveDepthCard(imageName: "dune.jpg")
                .frame(width: 300, height: 450)
        } else {
            Text("Requires iOS 17")
                .foregroundColor(.white)
        }
    }
}
