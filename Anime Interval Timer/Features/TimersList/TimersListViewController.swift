//
//  TimerViewController.swift
//  Anime Interval Timer
//
//  Created by Nazlı on 17.02.2026.
//


import UIKit

final class TimersListViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView?
    @IBOutlet private weak var addNewTimerButton: UIButton?

    private let viewModel = TimersListViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Timers"

        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.tableFooterView = UIView()
        tableView?.rowHeight = 170
        tableView?.estimatedRowHeight = 170

        viewModel.reload()
        tableView?.reloadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "My Timers"

        viewModel.reload()
        tableView?.reloadData()
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

    @IBAction private func addNewTimerTapped(_ sender: UIButton) {
        let createVC = CreateTimerViewController()
        createVC.delegate = self
        createVC.availableEmojis = viewModel.availableEmojis
        navigationController?.pushViewController(createVC, animated: true)
    }
}

extension TimersListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfTimers
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath) as? TimerTableViewCell else {
            return UITableViewCell()
        }

        let display = viewModel.timer(at: indexPath.row)
        cell.configure(with: display)

        cell.onTapDelete = { [weak self, weak tableView] in
            guard let self, let tableView else { return }
            self.viewModel.deleteTimer(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }

        cell.onTapStart = { [weak self] in
            self?.startTimer(at: indexPath.row)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        viewModel.deleteTimer(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func startTimer(at index: Int) {
        guard let updatedTimer = viewModel.markTimerAsUsed(at: index) else { return }

        tableView?.reloadData()

        let timerVC = TimerRunViewController()
        timerVC.timer = updatedTimer
        navigationController?.pushViewController(timerVC, animated: true)
    }
}

extension TimersListViewController: CreateTimerViewControllerDelegate {
    func createTimerViewController(_ viewController: CreateTimerViewController, didCreate timer: AnimeTimer) {
        viewModel.addNewTimer(timer)
        tableView?.reloadData()
    }

    func createTimerViewControllerDidCancel(_ viewController: CreateTimerViewController) {
        // no-op
    }
}
