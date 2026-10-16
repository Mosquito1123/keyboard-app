import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

public enum Theme {
    public struct RGBA: Sendable, Equatable {
        public var red: Double
        public var green: Double
        public var blue: Double
        public var alpha: Double

        public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }

    /// One warm-ink color that resolves for light and dark.
    /// Brand colors that should not flip (the mic, for example) use the same value twice.
    public struct Swatch: Sendable, Equatable {
        public var light: RGBA
        public var dark: RGBA

        public init(light: RGBA, dark: RGBA) {
            self.light = light
            self.dark = dark
        }

        public init(_ both: RGBA) {
            self.light = both
            self.dark = both
        }
    }

    public static let canvas = Swatch(
        light: RGBA(red: 0.945, green: 0.925, blue: 0.898),
        dark: RGBA(red: 0.086, green: 0.075, blue: 0.067)
    )
    public static let card = Swatch(
        light: RGBA(red: 0.988, green: 0.978, blue: 0.964),
        dark: RGBA(red: 0.141, green: 0.122, blue: 0.106)
    )
    public static let hairline = Swatch(
        light: RGBA(red: 0.820, green: 0.784, blue: 0.735),
        dark: RGBA(red: 0.227, green: 0.200, blue: 0.173)
    )
    public static let keyFill = Swatch(
        light: RGBA(red: 1.0, green: 0.996, blue: 0.988),
        dark: RGBA(red: 0.953, green: 0.933, blue: 0.902)
    )
    public static let keyFillPressed = Swatch(
        light: RGBA(red: 0.710, green: 0.650, blue: 0.575),
        dark: RGBA(red: 0.690, green: 0.640, blue: 0.575)
    )
    public static let keyLabel = Swatch(
        light: RGBA(red: 0.102, green: 0.086, blue: 0.071),
        dark: RGBA(red: 0.102, green: 0.086, blue: 0.071)
    )
    public static let quietKey = Swatch(
        light: RGBA(red: 0.800, green: 0.758, blue: 0.700),
        dark: RGBA(red: 0.180, green: 0.161, blue: 0.145)
    )
    public static let quietKeyPressed = Swatch(
        light: RGBA(red: 0.620, green: 0.570, blue: 0.505),
        dark: RGBA(red: 0.340, green: 0.300, blue: 0.255)
    )
    public static let mic = Swatch(RGBA(red: 0.769, green: 0.333, blue: 0.165))
    public static let micPressed = Swatch(RGBA(red: 0.560, green: 0.220, blue: 0.095))
    public static let onMic = Swatch(RGBA(red: 1.0, green: 0.973, blue: 0.953))
    /// Sage, used only for rewrite so it stays distinct from the mic.
    public static let rewriteFill = Swatch(
        light: RGBA(red: 0.275, green: 0.420, blue: 0.340),
        dark: RGBA(red: 0.345, green: 0.455, blue: 0.384)
    )
    public static let rewritePressed = Swatch(
        light: RGBA(red: 0.190, green: 0.310, blue: 0.245),
        dark: RGBA(red: 0.240, green: 0.330, blue: 0.275)
    )
    public static let onRewrite = Swatch(RGBA(red: 0.957, green: 0.976, blue: 0.961))
    public static let muted = Swatch(
        light: RGBA(red: 0.420, green: 0.375, blue: 0.325),
        dark: RGBA(red: 0.718, green: 0.667, blue: 0.612)
    )
    public static let statusFill = Swatch(
        light: RGBA(red: 0.930, green: 0.900, blue: 0.855),
        dark: RGBA(red: 0.165, green: 0.141, blue: 0.118)
    )
    public static let statusText = Swatch(
        light: RGBA(red: 0.360, green: 0.230, blue: 0.120),
        dark: RGBA(red: 0.953, green: 0.902, blue: 0.784)
    )
    /// Primary text. Cream on the dark ink canvas, ink on the light paper canvas.
    public static let cream = Swatch(
        light: RGBA(red: 0.122, green: 0.098, blue: 0.082),
        dark: RGBA(red: 0.953, green: 0.933, blue: 0.902)
    )
    public static let listeningFill = Swatch(
        light: RGBA(red: 0.980, green: 0.900, blue: 0.820),
        dark: RGBA(red: 0.300, green: 0.165, blue: 0.100)
    )
    public static let successFill = Swatch(
        light: RGBA(red: 0.860, green: 0.920, blue: 0.860),
        dark: RGBA(red: 0.150, green: 0.240, blue: 0.175)
    )
    public static let successText = Swatch(
        light: RGBA(red: 0.120, green: 0.280, blue: 0.170),
        dark: RGBA(red: 0.820, green: 0.940, blue: 0.840)
    )
    public static let dangerFill = Swatch(
        light: RGBA(red: 0.970, green: 0.880, blue: 0.840),
        dark: RGBA(red: 0.340, green: 0.150, blue: 0.110)
    )
    public static let dangerText = Swatch(
        light: RGBA(red: 0.520, green: 0.150, blue: 0.080),
        dark: RGBA(red: 1.0, green: 0.860, blue: 0.780)
    )
}

#if canImport(UIKit)
public extension Theme.Swatch {
    var uiColor: UIColor {
        UIColor { traits in
            let rgba = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
        }
    }
}

public extension Theme.RGBA {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

#if canImport(SwiftUI)
public extension Theme.Swatch {
    var color: Color {
        #if canImport(UIKit)
        Color(uiColor: uiColor)
        #else
        Color(red: dark.red, green: dark.green, blue: dark.blue, opacity: dark.alpha)
        #endif
    }
}
#endif
