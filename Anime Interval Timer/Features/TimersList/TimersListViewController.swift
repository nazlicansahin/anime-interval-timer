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
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var subtitleLabel: UILabel?
    @IBOutlet private weak var addNewTimerStack: UIStackView?

    private let viewModel = TimersListViewModel()
    private let decorView = ChibiDecorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Timers"

        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.tableFooterView = UIView()
        tableView?.rowHeight = 170
        tableView?.estimatedRowHeight = 170

        applyChibiDesign()
        viewModel.reload()
        tableView?.reloadData()
    }

    private func applyChibiDesign() {
        titleLabel?.font = AppDesign.titleFont()
        subtitleLabel?.font = AppDesign.captionFont()
        subtitleLabel?.text = "Choose a timer or create new one! ✨"
        decorView.translatesAutoresizingMaskIntoConstraints = false
        if view.subviews.count > 0 {
            view.insertSubview(decorView, at: 1)
        } else {
            view.addSubview(decorView)
        }
        NSLayoutConstraint.activate([
            decorView.topAnchor.constraint(equalTo: view.topAnchor),
            decorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            decorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            decorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        addNewTimerStack?.layer.cornerRadius = AppDesign.cornerRadiusPill
        addNewTimerStack?.clipsToBounds = true
        addNewTimerStack?.backgroundColor = UIColor(red: 1, green: 0.98, blue: 0.99, alpha: 0.95)
        addNewTimerStack?.layer.borderWidth = 0.5
        addNewTimerStack?.layer.borderColor = UIColor(red: 1, green: 0.9, blue: 0.95, alpha: 0.6).cgColor
        addNewTimerStack?.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        addNewTimerStack?.isLayoutMarginsRelativeArrangement = true
        addNewTimerStack?.subviews.compactMap { $0 as? UILabel }.forEach { $0.font = AppDesign.bodyFont() }
        addNewTimerButton?.layer.cornerRadius = 20
        addNewTimerButton?.clipsToBounds = true
        tableView?.backgroundColor = .clear
        tableView?.separatorStyle = .none
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

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfTimers
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 0 : 8
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath) as? TimerTableViewCell else {
            return UITableViewCell()
        }

        let display = viewModel.timer(at: indexPath.section)
        cell.configure(with: display)

        cell.onTapDelete = { [weak self, weak tableView] in
            guard let self, let tableView else { return }
            self.viewModel.deleteTimer(at: indexPath.section)
            tableView.deleteSections([indexPath.section], with: .automatic)
        }

        cell.onTapStart = { [weak self] in
            self?.startTimer(at: indexPath.section)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        viewModel.deleteTimer(at: indexPath.section)
        tableView.deleteSections([indexPath.section], with: .automatic)
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
