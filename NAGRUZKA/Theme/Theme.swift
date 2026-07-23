//
//  Theme.swift
//  NAGRUZKA
//

import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8) / 255
        let b = CGFloat(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }

    static func dynamic(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

enum AppTheme {
    static let background = Color.dynamic(light: "EFEDE7", dark: "141410")
    static let foreground = Color.dynamic(light: "141410", dark: "F5F3EE")
    static let card = Color.dynamic(light: "FFFFFF", dark: "1F1F1B")
    static let mutedForeground = Color.dynamic(light: "7A7A6E", dark: "9B9B8E")
    static let chip = Color.dynamic(light: "EFEDE7", dark: "2A2A25")
    static let border = Color.dynamic(light: "141410", dark: "FFFFFF").opacity(0.09)

    static let accent = Color(hex: "FF3D20")

    static let hero = Color.dynamic(light: "141410", dark: "0A0A08")

    static let positive = Color.dynamic(light: "00875A", dark: "4ADE80")
    static let negative = Color.dynamic(light: "E5320A", dark: "FF8A80")
}
