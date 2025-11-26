import UIKit

extension UIColor {
    // Extract HSB components safely
    var hsbComponents: (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        // UIColor may be in different color spaces; getHue returns false if not convertible.
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return (h, s, b, a)
        }

        // Fallback: convert via CIColor to RGB, then approximate HSB.
        var r: CGFloat = 0
        var g: CGFloat = 0
        var bl: CGFloat = 0
        var alpha: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &bl, alpha: &alpha) {
            let maxV = max(r, max(g, bl))
            let minV = min(r, min(g, bl))
            let delta = maxV - minV

            var hue: CGFloat = 0
            if delta != 0 {
                if maxV == r {
                    hue = (g - bl) / delta
                } else if maxV == g {
                    hue = 2 + (bl - r) / delta
                } else {
                    hue = 4 + (r - g) / delta
                }
                hue /= 6
                if hue < 0 { hue += 1 }
            }

            let brightness = maxV
            let saturation = brightness == 0 ? 0 : (delta / brightness)
            return (hue, saturation, brightness, alpha)
        }

        // As a last resort, return zeros
        return (0, 0, 0, 1)
    }

    var saturation: CGFloat {
        hsbComponents.s
    }

    var brightness: CGFloat {
        hsbComponents.b
    }

    // Perceived brightness using ITU-R BT.601 luma coefficients on sRGB
    var perceivedBrightness: CGFloat {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            // Standard luma approximation
            return (0.299 * r + 0.587 * g + 0.114 * b)
        }
        // If RGB extraction fails, fall back to HSB brightness
        return brightness
    }

    // Slightly increase saturation to favor vivid colors for gradients
    func saturatedAdjusted(factor: CGFloat = 1.15) -> UIColor {
        let comps = hsbComponents
        let newS = min(max(comps.s * factor, 0), 1)
        return UIColor(hue: comps.h, saturation: newS, brightness: comps.b, alpha: comps.a)
    }

    // Simple perceptual-ish distance in HSB space
    func isClose(to other: UIColor, threshold: CGFloat = 0.08) -> Bool {
        let a = self.hsbComponents
        let b = other.hsbComponents

        // Hue is circular; compute minimal distance
        let dh = min(abs(a.h - b.h), 1 - abs(a.h - b.h))
        let ds = abs(a.s - b.s)
        let db = abs(a.b - b.b)

        // Weighted sum; tune weights to taste
        let distance = (dh * 0.6) + (ds * 0.25) + (db * 0.15)
        return distance < threshold
    }
}
