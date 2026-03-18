import UIKit

enum TimerPhase: Int, CaseIterable {
    case start = 0
    case focus = 1
    case break_ = 2

    var bgImageName: String {
        switch self {
        case .start: return "bg-green"
        case .focus: return "bg-pink"
        case .break_: return "bg-blue"
        }
    }

    var animeImageName: (study: String, workout: String) {
        switch self {
        case .start: return ("start-study", "start-workout")
        case .focus: return ("focus-study", "focus-workout")
        case .break_: return ("break-study", "break-workout")
        }
    }

    var stateTitle: String {
        switch self {
        case .start: return "Start"
        case .focus: return "Focus"
        case .break_: return "Break"
        }
    }

    var startBtnImageName: String {
        switch self {
        case .start: return "start-btn-green"
        case .focus: return "start-btn-pink"
        case .break_: return "start-btn-blue"
        }
    }

    var stopBtnImageName: String {
        switch self {
        case .start: return "stop-btn-green"
        case .focus: return "stop-btn-pink"
        case .break_: return "stop-btn-blue"
        }
    }
}

final class TimerRunViewController: UIViewController {

    var timer: AnimeTimer?

    private var phase: TimerPhase = .start
    private var currentLoop: Int = 0
    private var remainingSeconds: TimeInterval = 0
    private var isRunning = false
    private var hasCompletedStart = false
    private var countdownTimer: Timer?

    private let contentStack = UIStackView()
    private let bgImageView = UIImageView()
    private let titleLabel = UILabel()
    private let emojiLabel = UILabel()
    private let animeImageView = UIImageView()
    private let timerLabel = UILabel()
    private let stateLabel = UILabel()
    private let prevTourButton = UIButton(type: .custom)
    private let controlButton = UIButton(type: .custom)
    private let nextTourButton = UIButton(type: .custom)

    private let finishContainer = UIView()
    private let finishBgImageView = UIImageView()
    private let finishJapaneseLabel = UILabel()
    private let finishRomajiLabel = UILabel()
    private var confettiEmitter: CAEmitterLayer?

    override func loadView() {
        view = UIView()
        view.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = timer?.title ?? "Timer"
        buildUI()
        buildFinishUI()
        resetToStart()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !finishContainer.isHidden { return }
        if !isRunning && !hasReachedFinish {
            startCountdown()
        }
        startSwayAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countdownTimer?.invalidate()
        countdownTimer = nil
        stopSwayAnimation()
    }

    private var hasReachedFinish = false

    private func startSwayAnimation() {
        stopSwayAnimation()
        animeImageView.layer.removeAllAnimations()
        let offset: CGFloat = 20
        UIView.animate(withDuration: 1.5, delay: 0.5, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.animeImageView.transform = CGAffineTransform(translationX: 0, y: -offset)
        }
    }

    private func stopSwayAnimation() {
        animeImageView.layer.removeAllAnimations()
        animeImageView.transform = .identity
    }

    private func buildUI() {
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        view.insertSubview(bgImageView, at: 0)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 20)
        view.addSubview(titleLabel)

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.textAlignment = .center
        emojiLabel.font = .systemFont(ofSize: 32)
        view.addSubview(emojiLabel)

        animeImageView.translatesAutoresizingMaskIntoConstraints = false
        animeImageView.contentMode = .scaleAspectFit
        view.addSubview(animeImageView)

        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textAlignment = .center
        timerLabel.font = .systemFont(ofSize: 37)
        view.addSubview(timerLabel)

        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.textAlignment = .center
        stateLabel.font = .systemFont(ofSize: 17)
        view.addSubview(stateLabel)

        let btnStack = UIStackView(arrangedSubviews: [prevTourButton, controlButton, nextTourButton])
        btnStack.axis = .horizontal
        btnStack.distribution = .fillEqually
        btnStack.spacing = 0
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btnStack)

        prevTourButton.setImage(mirroredImage(named: "next-tour-btn"), for: .normal)
        prevTourButton.addTarget(self, action: #selector(prevTourTapped), for: .touchUpInside)

        nextTourButton.setImage(UIImage(named: "next-tour-btn"), for: .normal)
        nextTourButton.addTarget(self, action: #selector(nextTourTapped), for: .touchUpInside)

        controlButton.addTarget(self, action: #selector(controlTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            emojiLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            animeImageView.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 32),
            animeImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 72),
            animeImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -72),
            animeImageView.heightAnchor.constraint(equalToConstant: 318),

            timerLabel.topAnchor.constraint(equalTo: animeImageView.bottomAnchor, constant: 16),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            btnStack.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 16),
            btnStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 57),
            btnStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -57),
            btnStack.heightAnchor.constraint(equalToConstant: 60),

            stateLabel.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 16),
            stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stateLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func buildFinishUI() {
        finishContainer.translatesAutoresizingMaskIntoConstraints = false
        finishContainer.isHidden = true
        finishContainer.clipsToBounds = false
        view.addSubview(finishContainer)

        finishBgImageView.translatesAutoresizingMaskIntoConstraints = false
        finishBgImageView.contentMode = .scaleAspectFill
        finishBgImageView.clipsToBounds = true
        finishBgImageView.image = UIImage(named: "bg-green")
        finishContainer.addSubview(finishBgImageView)

        finishJapaneseLabel.translatesAutoresizingMaskIntoConstraints = false
        finishJapaneseLabel.text = "おめでとう 先輩"
        finishJapaneseLabel.font = .systemFont(ofSize: 36)
        finishJapaneseLabel.textAlignment = .center
        finishContainer.addSubview(finishJapaneseLabel)

        finishRomajiLabel.translatesAutoresizingMaskIntoConstraints = false
        finishRomajiLabel.text = "Omedetō Senpai"
        finishRomajiLabel.font = .systemFont(ofSize: 24)
        finishRomajiLabel.textAlignment = .center
        finishRomajiLabel.alpha = 0.9
        finishContainer.addSubview(finishRomajiLabel)

        NSLayoutConstraint.activate([
            finishContainer.topAnchor.constraint(equalTo: view.topAnchor),
            finishContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            finishContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            finishContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            finishBgImageView.topAnchor.constraint(equalTo: finishContainer.topAnchor),
            finishBgImageView.leadingAnchor.constraint(equalTo: finishContainer.leadingAnchor),
            finishBgImageView.trailingAnchor.constraint(equalTo: finishContainer.trailingAnchor),
            finishBgImageView.bottomAnchor.constraint(equalTo: finishContainer.bottomAnchor),

            finishJapaneseLabel.centerXAnchor.constraint(equalTo: finishContainer.centerXAnchor),
            finishJapaneseLabel.centerYAnchor.constraint(equalTo: finishContainer.centerYAnchor, constant: -20),

            finishRomajiLabel.topAnchor.constraint(equalTo: finishJapaneseLabel.bottomAnchor, constant: 12),
            finishRomajiLabel.centerXAnchor.constraint(equalTo: finishContainer.centerXAnchor),
        ])
    }

    private func addConfettiEmitter(to container: UIView) {
        confettiEmitter?.removeFromSuperlayer()
        let bounds = container.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -30)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        emitter.emitterShape = .line

        let colors: [UIColor] = [.systemPink, .systemYellow, .systemGreen, .systemOrange, .systemPurple, .systemRed, .systemCyan]
        var cells: [CAEmitterCell] = []

        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 3
            cell.lifetime = 6
            cell.velocity = 100
            cell.velocityRange = 40
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 3
            cell.spin = 2
            cell.spinRange = 2
            cell.scale = 0.12
            cell.scaleRange = 0.08
            cell.alphaSpeed = -0.12
            cell.color = color.cgColor
            cell.contents = makeConfettiCGImage(color: color)
            cells.append(cell)
        }

        let starCell = CAEmitterCell()
        starCell.birthRate = 1
        starCell.lifetime = 5
        starCell.velocity = 80
        starCell.velocityRange = 30
        starCell.emissionLongitude = .pi
        starCell.emissionRange = .pi / 3
        starCell.spin = 3
        starCell.spinRange = 1
        starCell.scale = 0.1
        starCell.scaleRange = 0.06
        starCell.alphaSpeed = -0.1
        starCell.color = UIColor.systemYellow.cgColor
        starCell.contents = makeStarCGImage()
        cells.append(starCell)

        emitter.emitterCells = cells
        emitter.frame = bounds
        emitter.masksToBounds = false
        container.layer.addSublayer(emitter)
        confettiEmitter = emitter
    }

    private func makeConfettiCGImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 4, height: 9)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.cgImage ?? makeFallbackCGImage(color: color)
    }

    private func makeFallbackCGImage(color: UIColor) -> CGImage? {
        let size = CGSize(width: 4, height: 4)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
    }

    private func makeStarCGImage() -> CGImage? {
        let size: CGFloat = 10
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { _ in
            UIColor.systemYellow.setFill()
            let path = UIBezierPath()
            let center = CGPoint(x: size / 2, y: size / 2)
            let outer: CGFloat = size / 2
            let inner: CGFloat = size / 5
            for i in 0..<10 {
                let r = i.isMultiple(of: 2) ? outer : inner
                let angle = CGFloat(i) * .pi / 5 - .pi / 2
                let p = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.close()
            path.fill()
        }
        return image.cgImage ?? makeFallbackCGImage(color: .systemYellow)
    }

    private func mirroredImage(named: String) -> UIImage? {
        guard let img = UIImage(named: named), let cg = img.cgImage else { return UIImage(named: named) }
        return UIImage(cgImage: cg, scale: img.scale, orientation: .upMirrored)
    }

    private func resetToStart() {
        phase = .start
        currentLoop = 0
        hasCompletedStart = false
        let duration = timer?.startDuration ?? 0
        remainingSeconds = duration
        isRunning = false
        countdownTimer?.invalidate()
        finishContainer.isHidden = true
        updateUI()
        updateControlButton()
    }

    private func updateUI() {
        titleLabel.text = timer?.title ?? "Timer"
        emojiLabel.text = timer?.emoji

        bgImageView.image = UIImage(named: phase.bgImageName)
        let names = phase.animeImageName
        let imgName = timer?.timerKind == .workout ? names.workout : names.study
        animeImageView.image = UIImage(named: imgName)

        timerLabel.text = Self.format(seconds: remainingSeconds)
        stateLabel.text = phase.stateTitle
    }

    private func updateControlButton() {
        controlButton.isHidden = false
        if isRunning {
            controlButton.setImage(UIImage(named: phase.stopBtnImageName), for: .normal)
        } else {
            controlButton.setImage(UIImage(named: phase.startBtnImageName), for: .normal)
        }
    }

    private func phaseDuration() -> TimeInterval {
        switch phase {
        case .start: return timer?.startDuration ?? 0
        case .focus: return timer?.focusDuration ?? 0
        case .break_: return timer?.breakDuration ?? 0
        }
    }

    private func advancePhase() {
        if phase == .start {
            hasCompletedStart = true
        }

        let nextRaw = phase.rawValue + 1
        if nextRaw > 2 {
            currentLoop += 1
            let loops = max(1, timer?.loopsCount ?? 1)
            if currentLoop >= loops {
                showFinish()
                return
            }
            phase = .focus
            remainingSeconds = timer?.focusDuration ?? 0
        } else {
            phase = TimerPhase(rawValue: nextRaw) ?? .focus
            remainingSeconds = phaseDuration()
        }
        updateUI()
        updateControlButton()
    }

    private func showFinish() {
        hasReachedFinish = true
        countdownTimer?.invalidate()
        countdownTimer = nil
        isRunning = false

        titleLabel.isHidden = true
        emojiLabel.isHidden = true
        animeImageView.isHidden = true
        timerLabel.isHidden = true
        stateLabel.isHidden = true
        prevTourButton.isHidden = true
        controlButton.isHidden = true
        nextTourButton.isHidden = true
        bgImageView.isHidden = true

        finishContainer.isHidden = false
        view.layoutIfNeeded()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.addConfettiEmitter(to: self.finishContainer)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func startCountdown() {
        guard !isRunning else { return }
        isRunning = true
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
        updateControlButton()
    }

    private func stopCountdown() {
        isRunning = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        updateControlButton()
    }

    @objc private func controlTapped() {
        if isRunning {
            stopCountdown()
        } else {
            startCountdown()
        }
    }

    private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            advancePhase()
            return
        }
        timerLabel.text = Self.format(seconds: remainingSeconds)
    }

    @objc private func prevTourTapped() {
        stopCountdown()
        if phase == .break_ {
            phase = .focus
            remainingSeconds = timer?.focusDuration ?? 0
        } else if phase == .focus {
            if currentLoop > 0 {
                currentLoop -= 1
                phase = .break_
                remainingSeconds = timer?.breakDuration ?? 0
            } else {
                phase = .start
                remainingSeconds = timer?.startDuration ?? 0
            }
        }
        updateUI()
        updateControlButton()
        startCountdown()
    }

    @objc private func nextTourTapped() {
        stopCountdown()
        advancePhase()
        if !finishContainer.isHidden { return }
        startCountdown()
    }

    private static func format(seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
