//
//  ViewController.swift
//  Anime Interval Timer
//
//  Created by Nazlı on 5.02.2026.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var chibiImageView: UIImageView!
    @IBOutlet private weak var gambareLabel: UILabel!
    @IBOutlet private weak var letsGoButton: UIButton!

    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        haptic.prepare()
        applyChibiFonts()
        setupLetsGoButton()
    }

    private func applyChibiFonts() {
        gambareLabel?.font = AppDesign.roundedFont(size: 42, weight: .bold)
        gambareLabel?.textAlignment = .center
        func styleSubviews(in view: UIView) {
            for subview in view.subviews {
                if let lbl = subview as? UILabel, lbl != gambareLabel {
                    lbl.font = lbl.font.pointSize > 20 ? AppDesign.titleFont() : AppDesign.captionFont()
                }
                if let btn = subview as? UIButton, btn != letsGoButton {
                    btn.titleLabel?.font = AppDesign.bodyFont()
                    btn.layer.cornerRadius = AppDesign.cornerRadiusButton
                    btn.clipsToBounds = true
                }
                styleSubviews(in: subview)
            }
        }
        styleSubviews(in: view)
    }

    private func setupLetsGoButton() {
        letsGoButton?.titleLabel?.font = AppDesign.roundedFont(size: 26, weight: .semibold)
        letsGoButton?.layer.cornerRadius = 28
        letsGoButton?.clipsToBounds = false
        letsGoButton?.layer.shadowColor = UIColor.black.cgColor
        letsGoButton?.layer.shadowOffset = CGSize(width: 0, height: 4)
        letsGoButton?.layer.shadowRadius = 8
        letsGoButton?.layer.shadowOpacity = 0.25
        letsGoButton?.addTarget(self, action: #selector(letsGoTouchDown), for: .touchDown)
        letsGoButton?.addTarget(self, action: #selector(letsGoTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        letsGoButton?.addTarget(self, action: #selector(letsGoPlayAffirmSound), for: .touchUpInside)
    }

    @objc private func letsGoPlayAffirmSound() {
        InteractionSuccessSound.playSuccesSecondAndThirdSeconds()
    }

    @objc private func letsGoTouchDown() {
        haptic.impactOccurred()
        UIView.animate(withDuration: 0.1) {
            self.letsGoButton?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func letsGoTouchUp() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            self.letsGoButton?.transform = .identity
        }, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppAmbientMusicController.shared.ensureAmbientForNonTimerScreen()
        startSwayAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSwayAnimation()
    }

    private func startSwayAnimation() {
        guard let imgView = chibiImageView else { return }
        stopSwayAnimation()
        imgView.layer.removeAllAnimations()
        let offset: CGFloat = 24
        UIView.animate(withDuration: 2.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            imgView.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }

    private func stopSwayAnimation() {
        chibiImageView?.layer.removeAllAnimations()
        chibiImageView?.transform = .identity
    }
}

