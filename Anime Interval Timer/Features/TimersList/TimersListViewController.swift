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
    @IBOutlet private weak var addNewTimerLabel: UILabel?

    private let viewModel = TimersListViewModel()
    private let decorView = ChibiDecorView()
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private var instantTimerStack: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )

        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.tableFooterView = UIView()
        tableView?.rowHeight = 170
        tableView?.estimatedRowHeight = 170

        haptic.prepare()
        applyChibiDesign()
        setupInstantTimerRow()
        viewModel.reload()
        tableView?.reloadData()
    }

    @objc private func openSettings() {
        let settings = SettingsViewController()
        navigationController?.pushViewController(settings, animated: true)
    }

    private func setupInstantTimerRow() {
        guard let addStack = addNewTimerStack, let tv = tableView, instantTimerStack == nil else { return }

        NSLayoutConstraint.deactivate(
            view.constraints.filter { c in
                let fi = c.firstItem as? UIView
                let si = c.secondItem as? UIView
                return fi === tv && si === addStack && c.firstAttribute == .top && c.secondAttribute == .bottom
            }
        )

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false
        row.layer.cornerRadius = AppDesign.cornerRadiusPill
        row.clipsToBounds = true
        row.backgroundColor = UIColor(red: 1, green: 0.97, blue: 0.98, alpha: 0.96)
        row.layoutMargins = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        row.isLayoutMarginsRelativeArrangement = true
        row.layer.borderWidth = 0.5
        row.layer.borderColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 0.4).cgColor

        let bolt = UIButton(type: .system)
        bolt.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        bolt.tintColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 1)
        bolt.backgroundColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 0.2)
        bolt.layer.cornerRadius = 24
        bolt.clipsToBounds = true
        bolt.translatesAutoresizingMaskIntoConstraints = false
        bolt.widthAnchor.constraint(equalToConstant: 48).isActive = true
        bolt.heightAnchor.constraint(equalToConstant: 48).isActive = true
        bolt.addTarget(self, action: #selector(instantTimerTapped), for: .touchUpInside)

        let lbl = UILabel()
        lbl.text = "Set instant timer"
        lbl.font = AppDesign.headlineFont()
        lbl.textColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 1)

        row.addArrangedSubview(bolt)
        row.addArrangedSubview(lbl)
        view.addSubview(row)
        instantTimerStack = row

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: addStack.bottomAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            row.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            row.heightAnchor.constraint(equalToConstant: 52),
            tv.topAnchor.constraint(equalTo: row.bottomAnchor, constant: 12),
        ])
    }

    @objc private func instantTimerTapped() {
        haptic.impactOccurred()
        let createVC = CreateTimerViewController()
        createVC.flowKind = .instant
        createVC.delegate = self
        createVC.availableEmojis = viewModel.availableEmojis
        navigationController?.pushViewController(createVC, animated: true)
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
        addNewTimerStack?.backgroundColor = UIColor(red: 1, green: 0.97, blue: 0.98, alpha: 0.96)
        addNewTimerStack?.layer.borderWidth = 0.5
        addNewTimerStack?.layer.borderColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 0.4).cgColor
        addNewTimerStack?.layoutMargins = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        addNewTimerStack?.isLayoutMarginsRelativeArrangement = true
        addNewTimerLabel?.font = AppDesign.headlineFont()
        addNewTimerLabel?.textColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 1)
        addNewTimerButton?.layer.cornerRadius = 24
        addNewTimerButton?.clipsToBounds = true
        addNewTimerButton?.layer.shadowColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 0.4).cgColor
        addNewTimerButton?.layer.shadowOffset = CGSize(width: 0, height: 2)
        addNewTimerButton?.layer.shadowRadius = 4
        addNewTimerButton?.layer.shadowOpacity = 0.3
        addNewTimerButton?.backgroundColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 0.25)
        addNewTimerButton?.tintColor = UIColor(red: 0.59, green: 0.42, blue: 0.60, alpha: 1)
        tableView?.backgroundColor = .clear
        tableView?.separatorStyle = .none
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = ""

        viewModel.reload()
        tableView?.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.alpha = 1
        title = ""
        AppAmbientMusicController.shared.ensureAmbientForNonTimerScreen()
    }

    @IBAction private func addNewTimerTapped(_ sender: UIButton) {
        haptic.impactOccurred()
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let timer = viewModel.storedTimer(at: indexPath.section) else { return }
        haptic.impactOccurred()
        let editVC = CreateTimerViewController()
        editVC.editingTimer = timer
        editVC.delegate = self
        editVC.availableEmojis = viewModel.availableEmojis
        navigationController?.pushViewController(editVC, animated: true)
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

    func createTimerViewController(_ viewController: CreateTimerViewController, didUpdate timer: AnimeTimer) {
        viewModel.updateExistingTimer(timer)
        tableView?.reloadData()
    }

    func createTimerViewControllerDidCancel(_ viewController: CreateTimerViewController) {
        // no-op
    }

    func createTimerViewController(_ viewController: CreateTimerViewController, didStartInstantTimer timer: AnimeTimer) {
        navigationController?.popViewController(animated: false)
        let timerVC = TimerRunViewController()
        timerVC.timer = timer
        navigationController?.pushViewController(timerVC, animated: true)
    }
}
