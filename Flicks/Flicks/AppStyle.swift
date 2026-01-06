import SwiftUI
import UIKit
import CoreGraphics

enum AppStyle {
    // Shared brand gradient for non-image screens
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.11, blue: 0.25),
                Color(red: 0.18, green: 0.19, blue: 0.38),
                Color(red: 0.42, green: 0.31, blue: 0.56)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Build a gradient from a set of UIColors, sorted for a smooth transition.
    static func gradient(from colors: [UIColor]) -> LinearGradient? {
        guard !colors.isEmpty else { return nil }

        let sorted = colors.sorted { a, b in
            a.perceivedBrightness < b.perceivedBrightness
        }
        let unique = uniqued(sorted)

        let gradientColors: [Color]
        if unique.count == 1, let only = unique.first {
            gradientColors = [Color(uiColor: only), Color(uiColor: only).opacity(0.7)]
        } else {
            gradientColors = unique.map { Color(uiColor: $0) }
        }

        return LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Sample representative colors from an image to drive gradients or accents.
    static func dominantColors(from image: UIImage, sampleGrid: Int = 4) -> [UIColor]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        var samples: [UIColor] = []
        for y in 0..<sampleGrid {
            for x in 0..<sampleGrid {
                let px = (width - 1) * x / max(sampleGrid - 1, 1)
                let py = (height - 1) * y / max(sampleGrid - 1, 1)
                if let color = colorAtPixel(cgImage: cgImage, x: px, y: py) {
                    samples.append(color.saturatedAdjusted())
                }
            }
        }

        let scored = samples.map { ($0, $0.saturation * $0.brightness) }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }

        return Array(scored.prefix(5))
    }
}

// MARK: - Internal helpers

private extension AppStyle {
    static func colorAtPixel(cgImage: CGImage, x: Int, y: Int) -> UIColor? {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data
        else { return nil }

        let ptr: UnsafePointer<UInt8> = CFDataGetBytePtr(data)
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        let offset = y * bytesPerRow + x * bytesPerPixel
        guard offset + 3 < CFDataGetLength(data) else { return nil }

        let r = CGFloat(ptr[offset]) / 255.0
        let g = CGFloat(ptr[offset + 1]) / 255.0
        let b = CGFloat(ptr[offset + 2]) / 255.0
        let a = CGFloat(ptr[offset + 3]) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    static func uniqued(_ colors: [UIColor], threshold: CGFloat = 0.08) -> [UIColor] {
        var result: [UIColor] = []
        for c in colors {
            if !result.contains(where: { $0.isClose(to: c, threshold: threshold) }) {
                result.append(c)
            }
        }
        return result
    }
}

struct SprocketHole: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white.opacity(0.3))
            .frame(width: 12, height: 8) // Rotated for horizontal
    }
}

struct FilmSeamDivider: View {
    var body: some View {
        GeometryReader { geometry in
            let count = Int(geometry.size.width / 20) // 12pt width + 8pt spacing
            HStack(spacing: 8) {
                ForEach(0..<count, id: \.self) { _ in
                    SprocketHole()
                }
            }
            .frame(width: geometry.size.width, alignment: .center)
        }
        .frame(height: 20)
        .background(Color.black.opacity(0.8))
    }
}
