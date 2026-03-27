import UIKit

protocol CreateTimerViewControllerDelegate: AnyObject {
    func createTimerViewController(_ viewController: CreateTimerViewController, didCreate timer: AnimeTimer)
    func createTimerViewControllerDidCancel(_ viewController: CreateTimerViewController)
    func createTimerViewController(_ viewController: CreateTimerViewController, didStartInstantTimer timer: AnimeTimer)
    func createTimerViewController(_ viewController: CreateTimerViewController, didUpdate timer: AnimeTimer)
}

extension CreateTimerViewControllerDelegate {
    func createTimerViewController(_ viewController: CreateTimerViewController, didStartInstantTimer timer: AnimeTimer) {}
    func createTimerViewController(_ viewController: CreateTimerViewController, didUpdate timer: AnimeTimer) {}
}

final class CreateTimerViewController: UIViewController {

    // MARK: - Types

    enum FlowKind {
        case create
        case instant
    }

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
    var flowKind: FlowKind = .create
    /// When set, screen acts as edit: fields prefilled, primary button saves in place.
    var editingTimer: AnimeTimer?
    private var selectedType: TimerType = .study

    // MARK: - UI (built in code)

    private let bgImageView = UIImageView()
    private let decorView = ChibiDecorView()
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
    private let formSubtitleLabel = UILabel()
    private weak var nameSectionContainer: UIView?

    // MARK: - Lifecycle

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    private func setupBackground() {
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        bgImageView.image = UIImage(named: AppDesign.backgroundImageName)
        view.insertSubview(bgImageView, at: 0)
        decorView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(decorView, aboveSubview: bgImageView)
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            decorView.topAnchor.constraint(equalTo: view.topAnchor),
            decorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            decorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            decorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        setupBackground()
        buildUI()
        setupActions()
        if let original = editingTimer {
            applyEditMode(original)
        } else {
            applyFlowKind()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppAmbientMusicController.shared.ensureAmbientForNonTimerScreen()
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
        guard let firstResponder = view.findFirstResponder() else { return }
        let rect = firstResponder.convert(firstResponder.bounds, to: scrollView)
        let targetRect = rect.insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(targetRect, animated: true)
    }

    // MARK: - Build UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.delaysContentTouches = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Subtitle
        formSubtitleLabel.text = "Design your perfect routine! 💪"
        formSubtitleLabel.font = AppDesign.captionFont()
        formSubtitleLabel.textColor = .secondaryLabel
        formSubtitleLabel.textAlignment = .center
        formSubtitleLabel.numberOfLines = 0
        formSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(formSubtitleLabel)

        // Timer Name
        let nameSection = makeSection(title: "✨ Timer Name", field: nameTextField)
        nameSectionContainer = nameSection
        contentStack.addArrangedSubview(nameSection)

        // Timer Type
        timerTypeButton.setTitle(selectedType.title, for: .normal)
        timerTypeButton.contentHorizontalAlignment = .leading
        let typeSection = makeSection(title: "📚 Timer Type", field: timerTypeButton)
        contentStack.addArrangedSubview(typeSection)

        // Loops
        loopsTextField.keyboardType = .numberPad
        loopsTextField.placeholder = "Required"
        let loopsSection = makeSection(title: "🔢 Number of Loops", field: loopsTextField)
        contentStack.addArrangedSubview(loopsSection)

        // Durations
        startLabel.text = "🚀 Start"
        focusLabel.text = "🎯 Focus"
        breakLabel.text = "☕ Break"
        [startTextField, focusTextField, breakTextField].forEach {
            $0.keyboardType = .numberPad
            $0.borderStyle = .none
            $0.textAlignment = .center
            $0.font = AppDesign.bodyFont()
        }
        startMinusBtn.setTitle("−", for: .normal)
        startPlusBtn.setTitle("+", for: .normal)
        focusMinusBtn.setTitle("−", for: .normal)
        focusPlusBtn.setTitle("+", for: .normal)
        breakMinusBtn.setTitle("−", for: .normal)
        breakPlusBtn.setTitle("+", for: .normal)
        startMinusBtn.titleLabel?.font = AppDesign.headlineFont()
        startPlusBtn.titleLabel?.font = AppDesign.headlineFont()
        startMinusBtn.backgroundColor = UIColor(red: 0.6, green: 0.9, blue: 0.85, alpha: 0.5)
        startPlusBtn.backgroundColor = UIColor(red: 0.6, green: 0.9, blue: 0.85, alpha: 0.5)
        focusMinusBtn.titleLabel?.font = AppDesign.headlineFont()
        focusPlusBtn.titleLabel?.font = AppDesign.headlineFont()
        focusMinusBtn.backgroundColor = UIColor.systemPink.withAlphaComponent(0.4)
        focusPlusBtn.backgroundColor = UIColor.systemPink.withAlphaComponent(0.4)
        breakMinusBtn.titleLabel?.font = AppDesign.headlineFont()
        breakPlusBtn.titleLabel?.font = AppDesign.headlineFont()
        breakMinusBtn.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 0.5)
        breakPlusBtn.backgroundColor = UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 0.5)
        [startMinusBtn, startPlusBtn, focusMinusBtn, focusPlusBtn, breakMinusBtn, breakPlusBtn].forEach {
            $0.layer.cornerRadius = AppDesign.cornerRadiusSmall
        }

        let startRow = makeDurationRow(label: startLabel, minus: startMinusBtn, field: startTextField, plus: startPlusBtn)
        let focusRow = makeDurationRow(label: focusLabel, minus: focusMinusBtn, field: focusTextField, plus: focusPlusBtn)
        let breakRow = makeDurationRow(label: breakLabel, minus: breakMinusBtn, field: breakTextField, plus: breakPlusBtn)
        let durationWraps: [(UIView, UIColor)] = [
            (startRow, UIColor(red: 0.85, green: 0.98, blue: 0.95, alpha: 0.9)),
            (focusRow, UIColor(red: 1, green: 0.92, blue: 0.95, alpha: 0.9)),
            (breakRow, UIColor(red: 0.9, green: 0.95, blue: 1, alpha: 0.9)),
        ]
        durationWraps.forEach { row, tint in
            let wrap = UIView()
            wrap.backgroundColor = tint
            wrap.layer.cornerRadius = AppDesign.cornerRadius
            wrap.addSubview(row)
            row.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 16),
                row.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -16),
                row.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -16),
            ])
            contentStack.addArrangedSubview(wrap)
        }
        startLabel.textColor = UIColor(red: 0.2, green: 0.6, blue: 0.55, alpha: 1)
        focusLabel.textColor = UIColor(red: 0.85, green: 0.35, blue: 0.5, alpha: 1)
        breakLabel.textColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1)

        // Buttons
        let btnStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        btnStack.axis = .horizontal
        btnStack.spacing = 16
        btnStack.distribution = .fillEqually
        cancelButton.configuration = .filled()
        cancelButton.configuration?.baseBackgroundColor = .systemGray
        cancelButton.configuration?.title = "Cancel"
        cancelButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppDesign.bodyFont()
            return outgoing
        }
        createButton.configuration = .filled()
        createButton.configuration?.baseBackgroundColor = .systemPink
        createButton.configuration?.title = "Create ✨"
        createButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppDesign.bodyFont()
            return outgoing
        }
        [cancelButton, createButton].forEach {
            $0.layer.cornerRadius = AppDesign.cornerRadiusButton
            $0.clipsToBounds = true
        }
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
        lbl.font = AppDesign.bodyFont()
        lbl.textColor = .label
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
        v.backgroundColor = UIColor(red: 1, green: 0.98, blue: 0.99, alpha: 0.92)
        v.layer.cornerRadius = AppDesign.cornerRadius
        v.layer.masksToBounds = true
        if let tf = field as? UITextField {
            tf.font = AppDesign.bodyFont()
            tf.borderStyle = .none
            tf.layer.cornerRadius = AppDesign.cornerRadiusSmall
            tf.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        }
        if let btn = field as? UIButton {
            btn.titleLabel?.font = AppDesign.bodyFont()
        }
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
        label.font = AppDesign.bodyFont()
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

    private func applyEditMode(_ original: AnimeTimer) {
        formSubtitleLabel.text = "Update your routine ✨"
        nameSectionContainer?.isHidden = false
        createButton.configuration?.title = "Save ✨"
        nameTextField.text = original.title
        loopsTextField.text = "\(original.loopsCount ?? 1)"
        startTextField.text = Self.format(seconds: original.startDuration)
        focusTextField.text = Self.format(seconds: original.focusDuration)
        breakTextField.text = Self.format(seconds: original.breakDuration)
        selectedType = original.timerKind == .workout ? .workout : .study
        timerTypeButton.setTitle(selectedType.title, for: .normal)
    }

    private func applyFlowKind() {
        switch flowKind {
        case .create:
            setInitialValuesCreate()
        case .instant:
            formSubtitleLabel.text = "Quick start — change times if you want ⚡️"
            nameSectionContainer?.isHidden = true
            createButton.configuration?.title = "Start ✨"
            loopsTextField.text = "1"
            startTextField.text = Self.format(seconds: 5)
            focusTextField.text = "00:30"
            breakTextField.text = "00:30"
        }
    }

    private func setInitialValuesCreate() {
        startTextField.text = "00:00"
        focusTextField.text = "00:30"
        breakTextField.text = "00:30"
        loopsTextField.text = ""
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    @objc private func cancelTapped() {
        delegate?.createTimerViewControllerDidCancel(self)
        navigationController?.popViewController(animated: true)
    }

    @objc private func createTapped() {
        let loopsTrimmed = (loopsTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let loops = Int(loopsTrimmed), loops > 0 else {
            presentValidationAlert(title: "Loops required", message: "Enter how many times the routine should repeat (1 or more).")
            return
        }

        let start = Self.parseDurationToSeconds(startTextField.text) ?? (flowKind == .instant ? 5 : 0)
        let focus = Self.parseDurationToSeconds(focusTextField.text) ?? 0
        let brk = Self.parseDurationToSeconds(breakTextField.text) ?? 0
        let emoji = availableEmojis.randomElement() ?? "⏳"

        if flowKind == .instant {
            let timer = AnimeTimer(
                id: UUID(),
                title: "",
                loopsCount: loops,
                startDuration: start,
                focusDuration: focus,
                breakDuration: brk,
                emoji: emoji,
                usageCount: 0,
                createdAt: Date(),
                timerKind: selectedType.kind
            )
            // Delegate pops this screen then pushes timer run — do not pop here or the timer VC gets popped.
            delegate?.createTimerViewController(self, didStartInstantTimer: timer)
            return
        }

        let title = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = title.isEmpty ? "My Timer" : title

        if let original = editingTimer {
            InteractionSuccessSound.playSuccesSecondAndThirdSeconds()
            let updated = AnimeTimer(
                id: original.id,
                title: name,
                loopsCount: loops,
                startDuration: start,
                focusDuration: focus,
                breakDuration: brk,
                emoji: original.emoji,
                usageCount: original.usageCount,
                createdAt: original.createdAt,
                timerKind: selectedType.kind
            )
            delegate?.createTimerViewController(self, didUpdate: updated)
            navigationController?.popViewController(animated: true)
            return
        }

        InteractionSuccessSound.playSuccesSecondAndThirdSeconds()

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

    private func presentValidationAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
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
        return TimeInterval(Int(t) ?? 0)
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
