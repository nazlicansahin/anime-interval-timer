//
//  ChibiDecorView.swift
//  Anime Interval Timer
//

import UIKit

/// Floating hearts, stars, plus signs for cute chibi background
final class ChibiDecorView: UIView {

    private var decorLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if decorLabels.isEmpty {
            addDecorElements()
        }
    }

    private func addDecorElements() {
        decorLabels.forEach { $0.removeFromSuperview() }
        decorLabels.removeAll()

        let symbols = ["♥︎", "✦", "+", "♡", "✧", "♥︎", "+", "✦"]
        let colors: [UIColor] = [
            UIColor(red: 1, green: 0.6, blue: 0.7, alpha: 0.45),
            UIColor(red: 1, green: 0.8, blue: 0.9, alpha: 0.4),
            UIColor(red: 0.9, green: 0.7, blue: 0.9, alpha: 0.35),
        ]

        let w = bounds.width
        let h = bounds.height
        guard w > 50, h > 50 else { return }

        for i in 0..<20 {
            let lbl = UILabel()
            lbl.text = symbols[i % symbols.count]
            lbl.font = .systemFont(ofSize: [16, 18, 20, 22, 24].randomElement() ?? 18, weight: .light)
            lbl.textColor = colors[i % colors.count]
            lbl.alpha = CGFloat.random(in: 0.3...0.55)
            lbl.sizeToFit()
            lbl.frame.origin = CGPoint(
                x: CGFloat.random(in: 0...(w - lbl.bounds.width)),
                y: CGFloat.random(in: 0...(h - lbl.bounds.height))
            )
            addSubview(lbl)
            decorLabels.append(lbl)
        }
    }
}
