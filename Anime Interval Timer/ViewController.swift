//
//  ViewController.swift
//  Anime Interval Timer
//
//  Created by Nazlı on 5.02.2026.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var chibiImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

