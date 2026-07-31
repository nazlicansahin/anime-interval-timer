//
//  AppDesign.swift
//  Anime Interval Timer
//

import UIKit

enum AppDesign {

    static let backgroundImageName = "background-img"

    static let accentPurple = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 1)
    static let accentPurpleSoft = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 0.25)
    static let accentPurpleMuted = UIColor(red: 0.68, green: 0.48, blue: 0.69, alpha: 1)
    static let cardBackground = UIColor(red: 1, green: 0.97, blue: 0.98, alpha: 0.96)
    static let cellBackground = UIColor(red: 1, green: 0.98, blue: 0.99, alpha: 0.95)
    static let primaryText = UIColor(red: 0.25, green: 0.18, blue: 0.28, alpha: 1)
    static let secondaryText = UIColor(red: 0.45, green: 0.35, blue: 0.48, alpha: 1)
    static let formSectionBackground = UIColor(red: 1, green: 0.98, blue: 0.99, alpha: 0.92)
    static let formFieldBackground = UIColor(red: 0.97, green: 0.95, blue: 0.98, alpha: 0.9)

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusButton: CGFloat = 20
    static let cornerRadiusCard: CGFloat = 24
    static let cornerRadiusPill: CGFloat = 22

    static func roundedFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else {
            return systemFont
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    static func titleFont() -> UIFont { roundedFont(size: 26, weight: .semibold) }
    static func headlineFont() -> UIFont { roundedFont(size: 20, weight: .medium) }
    static func bodyFont() -> UIFont { roundedFont(size: 17, weight: .regular) }
    static func captionFont() -> UIFont { roundedFont(size: 14, weight: .regular) }
    static func smallFont() -> UIFont { roundedFont(size: 12, weight: .regular) }
}
