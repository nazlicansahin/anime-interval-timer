import UIKit

protocol CreateTimerViewControllerDelegate: AnyObject {
    func createTimerViewController(_ viewController: CreateTimerViewController, didCreate timer: AnimeTimer)
    func createTimerViewControllerDidCancel(_ viewController: CreateTimerViewController)
}

final class CreateTimerViewController: UIViewController {

    // MARK: - Types

    enum TimerType: CaseIterable {
        case study
        case workout
        var title: String {
            switch self {
            case .study: return "Study"
            case .workout: return "Workout"
            }
        }
        var kind: TimerKind {
            switch self {
            case .study: return .study
            case .workout: return .workout
            }
        }
    }

    // MARK: - Dependencies

    weak var delegate: CreateTimerViewControllerDelegate?
    var availableEmojis: [String] = ["⏳", "📚", "💪", "✨", "🔥", "🌸"]
    private var selectedType: TimerType = .study

    // MARK: - UI (built in code)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let nameTextField = UITextField()
    private let timerTypeButton = UIButton(type: .system)
    private let loopsTextField = UITextField()
    private let startLabel = UILabel()
    private let startMinusBtn = UIButton(type: .system)
    private let startTextField = UITextField()
    private let startPlusBtn = UIButton(type: .system)
    private let focusLabel = UILabel()
    private let focusMinusBtn = UIButton(type: .system)
    private let focusTextField = UITextField()
    private let focusPlusBtn = UIButton(type: .system)
    private let breakLabel = UILabel()
    private let breakMinusBtn = UIButton(type: .system)
    private let breakTextField = UITextField()
    private let breakPlusBtn = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Timer"
        buildUI()
        setupActions()
        setInitialValues()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        let keyboardFrameInView = view.convert(frame, from: nil)
        let keyboardHeight = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        DispatchQueue.main.async { [weak self] in
            self?.scrollToActiveField()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToActiveField() {
        guard let firstResponder = view.findFirstResponder() as? UIView else { return }
        let rect = firstResponder.convert(firstResponder.bounds, to: scrollView)
        let targetRect = rect.insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(targetRect, animated: true)
    }

    // MARK: - Build UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.delaysContentTouches = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Timer Name
        let nameSection = makeSection(title: "Timer Name", field: nameTextField)
        contentStack.addArrangedSubview(nameSection)

        // Timer Type
        timerTypeButton.setTitle(selectedType.title, for: .normal)
        timerTypeButton.contentHorizontalAlignment = .leading
        let typeSection = makeSection(title: "Timer Type", field: timerTypeButton)
        contentStack.addArrangedSubview(typeSection)

        // Loops
        loopsTextField.keyboardType = .numberPad
        let loopsSection = makeSection(title: "Number of Loops", field: loopsTextField)
        contentStack.addArrangedSubview(loopsSection)

        // Durations
        startLabel.text = "Start"
        focusLabel.text = "Focus"
        breakLabel.text = "Break"
        [startTextField, focusTextField, breakTextField].forEach {
            $0.keyboardType = .numbersAndPunctuation
            $0.borderStyle = .roundedRect
            $0.textAlignment = .center
        }
        startMinusBtn.setTitle("−", for: .normal)
        startPlusBtn.setTitle("+", for: .normal)
        focusMinusBtn.setTitle("−", for: .normal)
        focusPlusBtn.setTitle("+", for: .normal)
        breakMinusBtn.setTitle("−", for: .normal)
        breakPlusBtn.setTitle("+", for: .normal)

        contentStack.addArrangedSubview(makeDurationRow(label: startLabel, minus: startMinusBtn, field: startTextField, plus: startPlusBtn))
        contentStack.addArrangedSubview(makeDurationRow(label: focusLabel, minus: focusMinusBtn, field: focusTextField, plus: focusPlusBtn))
        contentStack.addArrangedSubview(makeDurationRow(label: breakLabel, minus: breakMinusBtn, field: breakTextField, plus: breakPlusBtn))

        // Buttons
        let btnStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        btnStack.axis = .horizontal
        btnStack.spacing = 16
        btnStack.distribution = .fillEqually
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.configuration = .filled()
        cancelButton.configuration?.baseBackgroundColor = .systemGray
        createButton.setTitle("Create", for: .normal)
        createButton.configuration = .filled()
        createButton.configuration?.baseBackgroundColor = .systemPink
        contentStack.addArrangedSubview(btnStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func makeSection(title: String, field: UIView) -> UIView {
        let v = UIView()
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .systemFont(ofSize: 17)
        field.translatesAutoresizingMaskIntoConstraints = false
        lbl.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(lbl)
        v.addSubview(field)
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: v.topAnchor, constant: 16),
            lbl.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            lbl.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            field.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: 8),
            field.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -16),
            field.heightAnchor.constraint(equalToConstant: 36),
            field.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -16),
        ])
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 8
        return v
    }

    private func makeDurationRow(label: UILabel, minus: UIButton, field: UITextField, plus: UIButton) -> UIView {
        let row = UIStackView(arrangedSubviews: [minus, field, plus])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        minus.translatesAutoresizingMaskIntoConstraints = false
        plus.translatesAutoresizingMaskIntoConstraints = false
        field.translatesAutoresizingMaskIntoConstraints = false
        minus.widthAnchor.constraint(equalToConstant: 44).isActive = true
        minus.heightAnchor.constraint(equalToConstant: 44).isActive = true
        plus.widthAnchor.constraint(equalToConstant: 44).isActive = true
        plus.heightAnchor.constraint(equalToConstant: 44).isActive = true
        field.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        let container = UIStackView(arrangedSubviews: [label, row])
        container.axis = .vertical
        container.spacing = 8
        label.font = .systemFont(ofSize: 17)
        return container
    }

    private func setupActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        nameTextField.delegate = self
        loopsTextField.delegate = self
        startTextField.delegate = self
        focusTextField.delegate = self
        breakTextField.delegate = self

        timerTypeButton.showsMenuAsPrimaryAction = true
        timerTypeButton.menu = UIMenu(children: TimerType.allCases.map { [weak self] t in
            UIAction(title: t.title, state: t == self?.selectedType ? .on : .off) { [weak self] _ in
                self?.selectedType = t
                self?.timerTypeButton.setTitle(t.title, for: .normal)
            }
        })

        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        startMinusBtn.addTarget(self, action: #selector(stepperStartMinus), for: .touchUpInside)
        startPlusBtn.addTarget(self, action: #selector(stepperStartPlus), for: .touchUpInside)
        focusMinusBtn.addTarget(self, action: #selector(stepperFocusMinus), for: .touchUpInside)
        focusPlusBtn.addTarget(self, action: #selector(stepperFocusPlus), for: .touchUpInside)
        breakMinusBtn.addTarget(self, action: #selector(stepperBreakMinus), for: .touchUpInside)
        breakPlusBtn.addTarget(self, action: #selector(stepperBreakPlus), for: .touchUpInside)
    }

    private func setInitialValues() {
        startTextField.text = "00:00"
        focusTextField.text = "00:30"
        breakTextField.text = "00:30"
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func cancelTapped() {
        delegate?.createTimerViewControllerDidCancel(self)
        navigationController?.popViewController(animated: true)
    }

    @objc private func createTapped() {
        let title = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = title.isEmpty ? "My Timer" : title
        let loops = Int((loopsTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        let start = Self.parseDurationToSeconds(startTextField.text) ?? 0
        let focus = Self.parseDurationToSeconds(focusTextField.text) ?? 0
        let brk = Self.parseDurationToSeconds(breakTextField.text) ?? 0
        let emoji = availableEmojis.randomElement() ?? "⏳"

        let timer = AnimeTimer(
            id: UUID(),
            title: name,
            loopsCount: loops,
            startDuration: start,
            focusDuration: focus,
            breakDuration: brk,
            emoji: emoji,
            usageCount: 0,
            createdAt: Date(),
            timerKind: selectedType.kind
        )
        delegate?.createTimerViewController(self, didCreate: timer)
        navigationController?.popViewController(animated: true)
    }

    @objc private func stepperStartMinus() { adjust(startTextField, by: -10) }
    @objc private func stepperStartPlus() { adjust(startTextField, by: 10) }
    @objc private func stepperFocusMinus() { adjust(focusTextField, by: -10) }
    @objc private func stepperFocusPlus() { adjust(focusTextField, by: 10) }
    @objc private func stepperBreakMinus() { adjust(breakTextField, by: -10) }
    @objc private func stepperBreakPlus() { adjust(breakTextField, by: 10) }

    private func adjust(_ field: UITextField, by delta: Int) {
        let sec = Self.parseDurationToSeconds(field.text) ?? 0
        field.text = Self.format(seconds: max(0, sec + TimeInterval(delta)))
    }

    private static func parseDurationToSeconds(_ raw: String?) -> TimeInterval? {
        let t = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if t.contains(":") {
            let p = t.split(separator: ":", omittingEmptySubsequences: false)
            guard p.count == 2 else { return nil }
            return TimeInterval((Int(p[0]) ?? 0) * 60 + (Int(p[1]) ?? 0))
        }
        return TimeInterval((Int(t) ?? 0) * 60)
    }

    private static func format(seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

extension CreateTimerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

private extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.findFirstResponder() { return found }
        }
        return nil
    }
}
