//
//  AppDesign.swift
//  Anime Interval Timer
//

import UIKit

enum AppDesign {

    static let backgroundImageName = "background-img"

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
