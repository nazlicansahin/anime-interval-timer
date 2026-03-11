//
//  TimerViewController.swift
//  Anime Interval Timer
//
//  Created by Nazlı on 17.02.2026.
//


import UIKit

final class TimersListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Timers"
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "My Timers"
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("navigationController:", navigationController as Any)
        print("navBarHidden:", navigationController?.isNavigationBarHidden as Any)

        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.alpha = 1
        title = "My Timers"
    }
}
