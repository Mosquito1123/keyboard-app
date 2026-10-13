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

    /// Warm ink, chosen for this project. Not a system-keyboard gray.
    public static let canvas = RGBA(red: 0.086, green: 0.075, blue: 0.067)
    public static let card = RGBA(red: 0.141, green: 0.122, blue: 0.106)
    public static let hairline = RGBA(red: 0.227, green: 0.200, blue: 0.173)
    public static let keyFill = RGBA(red: 0.953, green: 0.933, blue: 0.902)
    public static let keyFillPressed = RGBA(red: 0.894, green: 0.867, blue: 0.824)
    public static let keyLabel = RGBA(red: 0.102, green: 0.086, blue: 0.071)
    public static let quietKey = RGBA(red: 0.180, green: 0.161, blue: 0.145)
    public static let mic = RGBA(red: 0.769, green: 0.333, blue: 0.165)
    public static let micPressed = RGBA(red: 0.620, green: 0.255, blue: 0.118)
    public static let onMic = RGBA(red: 1.0, green: 0.973, blue: 0.953)
    /// Muted sage, used only for the rewrite control so it is distinct from the mic key.
    public static let rewriteFill = RGBA(red: 0.345, green: 0.455, blue: 0.384)
    public static let rewritePressed = RGBA(red: 0.275, green: 0.365, blue: 0.310)
    public static let onRewrite = RGBA(red: 0.957, green: 0.976, blue: 0.961)
    public static let muted = RGBA(red: 0.718, green: 0.667, blue: 0.612)
    public static let statusFill = RGBA(red: 0.165, green: 0.141, blue: 0.118)
    public static let statusText = RGBA(red: 0.953, green: 0.902, blue: 0.784)
    public static let cream = RGBA(red: 0.953, green: 0.933, blue: 0.902)
}

#if canImport(UIKit)
public extension Theme.RGBA {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

#if canImport(SwiftUI)
public extension Theme.RGBA {
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
#endif
