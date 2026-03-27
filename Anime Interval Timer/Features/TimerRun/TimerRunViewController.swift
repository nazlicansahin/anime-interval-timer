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

    var stateTitle: (japanese: String, english: String) {
        switch self {
        case .start: return ("準備できた？先輩", "Ready, Senpai?")
        case .focus: return ("できるよ！先輩", "You can do it, Senpai!")
        case .break_: return ("休憩だよ、先輩", "Break time, Senpai!")
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

    var phaseIconImageName: String {
        switch self {
        case .start: return "rocket"
        case .focus: return "dart"
        case .break_: return "coffe"
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
    private let phaseIconImageView = UIImageView()
    private let animeImageView = UIImageView()
    private let timerLabel = UILabel()
    private let stateLabel = UILabel()
    private let stateEnglishLabel = UILabel()
    private let prevTourButton = UIButton(type: .custom)
    private let controlButton = UIButton(type: .custom)
    private let nextTourButton = UIButton(type: .custom)

    private let finishContainer = UIView()
    private let finishBgImageView = UIImageView()
    private let finishJapaneseLabel = UILabel()
    private let finishRomajiLabel = UILabel()
    private let finishEnglishLabel = UILabel()
    private var confettiEmitter: CAEmitterLayer?
    private let sessionAudio = TimerRunAudioController()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        buildUI()
        buildFinishUI()
        resetToStart()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isMovingToParent || isBeingPresented {
            AppAmbientMusicController.shared.beginTimerRunSession()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionAudio.activateSession()
        sessionAudio.refreshVolumes()
        if !finishContainer.isHidden { return }
        sessionAudio.syncMusic(phase: phase, timerKind: timer?.timerKind ?? .study)
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
        confettiEmitter?.removeFromSuperlayer()
        confettiEmitter = nil
        sessionAudio.deactivateSession()
        if isMovingFromParent || isBeingDismissed {
            AppAmbientMusicController.shared.endTimerRunSession()
        }
    }

    private var hasReachedFinish = false
    /// One shot of 3scounter per start/focus/break segment when countdown hits 4s left.
    private var playedLastFourSecondCounterThisSegment = false

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

        phaseIconImageView.translatesAutoresizingMaskIntoConstraints = false
        phaseIconImageView.contentMode = .scaleAspectFit
        view.addSubview(phaseIconImageView)

        animeImageView.translatesAutoresizingMaskIntoConstraints = false
        animeImageView.contentMode = .scaleAspectFit
        view.addSubview(animeImageView)

        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.textAlignment = .center
        timerLabel.font = .systemFont(ofSize: 37)
        view.addSubview(timerLabel)

        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.textAlignment = .center
        stateLabel.font = AppDesign.roundedFont(size: 20, weight: .medium)
        stateLabel.textColor = .white
        stateLabel.layer.shadowColor = UIColor.black.cgColor
        stateLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        stateLabel.layer.shadowRadius = 2
        stateLabel.layer.shadowOpacity = 0.5
        stateLabel.numberOfLines = 0
        view.addSubview(stateLabel)

        stateEnglishLabel.translatesAutoresizingMaskIntoConstraints = false
        stateEnglishLabel.textAlignment = .center
        stateEnglishLabel.font = AppDesign.captionFont()
        stateEnglishLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        stateEnglishLabel.layer.shadowColor = UIColor.black.cgColor
        stateEnglishLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        stateEnglishLabel.layer.shadowRadius = 1
        stateEnglishLabel.layer.shadowOpacity = 0.4
        view.addSubview(stateEnglishLabel)

        let btnStack = UIStackView(arrangedSubviews: [prevTourButton, controlButton, nextTourButton])
        btnStack.axis = .horizontal
        btnStack.distribution = .equalSpacing
        btnStack.alignment = .center
        btnStack.spacing = 8
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btnStack)

        [prevTourButton, controlButton, nextTourButton].forEach {
            $0.imageView?.contentMode = .scaleAspectFit
            $0.contentHorizontalAlignment = .center
            $0.contentVerticalAlignment = .center
        }
        prevTourButton.setImage(mirroredImage(named: "next-tour-btn"), for: .normal)
        prevTourButton.addTarget(self, action: #selector(prevTourTapped), for: .touchUpInside)

        nextTourButton.setImage(UIImage(named: "next-tour-btn"), for: .normal)
        nextTourButton.addTarget(self, action: #selector(nextTourTapped), for: .touchUpInside)

        controlButton.addTarget(self, action: #selector(controlTapped), for: .touchUpInside)

        prevTourButton.translatesAutoresizingMaskIntoConstraints = false
        controlButton.translatesAutoresizingMaskIntoConstraints = false
        nextTourButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            phaseIconImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            phaseIconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            phaseIconImageView.widthAnchor.constraint(equalToConstant: 49),
            phaseIconImageView.heightAnchor.constraint(equalToConstant: 49),

            animeImageView.topAnchor.constraint(equalTo: phaseIconImageView.bottomAnchor, constant: 32),
            animeImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 72),
            animeImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -72),
            animeImageView.heightAnchor.constraint(equalToConstant: 318),

            timerLabel.topAnchor.constraint(equalTo: animeImageView.bottomAnchor, constant: 16),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            btnStack.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 16),
            btnStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            prevTourButton.widthAnchor.constraint(equalToConstant: 80),
            prevTourButton.heightAnchor.constraint(equalToConstant: 80),
            controlButton.widthAnchor.constraint(equalToConstant: 100),
            controlButton.heightAnchor.constraint(equalToConstant: 100),
            nextTourButton.widthAnchor.constraint(equalToConstant: 80),
            nextTourButton.heightAnchor.constraint(equalToConstant: 80),

            stateLabel.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 16),
            stateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            stateEnglishLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 4),
            stateEnglishLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stateEnglishLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
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
        finishJapaneseLabel.text = "やった！おめでとう 先輩！！"
        finishJapaneseLabel.font = AppDesign.roundedFont(size: 40, weight: .bold)
        finishJapaneseLabel.textAlignment = .center
        finishJapaneseLabel.textColor = UIColor(red: 0.95, green: 0.35, blue: 0.45, alpha: 1)
        finishJapaneseLabel.layer.shadowColor = UIColor.white.cgColor
        finishJapaneseLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        finishJapaneseLabel.layer.shadowRadius = 2
        finishJapaneseLabel.layer.shadowOpacity = 0.8
        finishJapaneseLabel.numberOfLines = 0
        finishContainer.addSubview(finishJapaneseLabel)

        finishRomajiLabel.translatesAutoresizingMaskIntoConstraints = false
        finishRomajiLabel.text = "Yatta! Omedetō Senpai!! ✨"
        finishRomajiLabel.font = AppDesign.roundedFont(size: 22, weight: .medium)
        finishRomajiLabel.textAlignment = .center
        finishRomajiLabel.textColor = UIColor(red: 0.6, green: 0.25, blue: 0.35, alpha: 1)
        finishRomajiLabel.alpha = 0.95
        finishContainer.addSubview(finishRomajiLabel)

        finishEnglishLabel.translatesAutoresizingMaskIntoConstraints = false
        finishEnglishLabel.text = "Congratulations, Senpai!"
        finishEnglishLabel.font = AppDesign.roundedFont(size: 18, weight: .medium)
        finishEnglishLabel.textAlignment = .center
        finishEnglishLabel.textColor = UIColor(red: 0.5, green: 0.2, blue: 0.3, alpha: 0.9)
        finishContainer.addSubview(finishEnglishLabel)

        NSLayoutConstraint.activate([
            finishContainer.topAnchor.constraint(equalTo: view.topAnchor),
            finishContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            finishContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            finishContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            finishBgImageView.topAnchor.constraint(equalTo: finishContainer.topAnchor),
            finishBgImageView.leadingAnchor.constraint(equalTo: finishContainer.leadingAnchor),
            finishBgImageView.trailingAnchor.constraint(equalTo: finishContainer.trailingAnchor),
            finishBgImageView.bottomAnchor.constraint(equalTo: finishContainer.bottomAnchor),

            finishJapaneseLabel.leadingAnchor.constraint(equalTo: finishContainer.leadingAnchor, constant: 24),
            finishJapaneseLabel.trailingAnchor.constraint(equalTo: finishContainer.trailingAnchor, constant: -24),
            finishJapaneseLabel.centerYAnchor.constraint(equalTo: finishContainer.centerYAnchor, constant: -30),

            finishRomajiLabel.topAnchor.constraint(equalTo: finishJapaneseLabel.bottomAnchor, constant: 12),
            finishRomajiLabel.centerXAnchor.constraint(equalTo: finishContainer.centerXAnchor),

            finishEnglishLabel.topAnchor.constraint(equalTo: finishRomajiLabel.bottomAnchor, constant: 8),
            finishEnglishLabel.centerXAnchor.constraint(equalTo: finishContainer.centerXAnchor),
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
            cell.birthRate = 1.5
            cell.lifetime = 3
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
        starCell.birthRate = 0.5
        starCell.lifetime = 2.5
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

        // Stop spawning after short burst to avoid memory buildup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.confettiEmitter?.birthRate = 0
        }
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
        playedLastFourSecondCounterThisSegment = false
        sessionAudio.stopAll()
        sessionAudio.syncMusic(phase: .start, timerKind: timer?.timerKind ?? .study)
        updateUI()
        updateControlButton()
    }

    private func updateUI() {
        let rawTitle = (timer?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        titleLabel.text = rawTitle.isEmpty ? "Quick start" : (timer?.title ?? "Timer")
        phaseIconImageView.image = UIImage(named: phase.phaseIconImageName)

        bgImageView.image = UIImage(named: phase.bgImageName)
        let names = phase.animeImageName
        let imgName = timer?.timerKind == .workout ? names.workout : names.study
        animeImageView.image = UIImage(named: imgName)

        timerLabel.text = Self.format(seconds: remainingSeconds)
        let state = phase.stateTitle
        stateLabel.text = state.japanese
        stateEnglishLabel.text = state.english
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
            sessionAudio.playTransitionSuccess()
            phase = .focus
            remainingSeconds = timer?.focusDuration ?? 0
        } else {
            sessionAudio.playTransitionSuccess()
            phase = TimerPhase(rawValue: nextRaw) ?? .focus
            remainingSeconds = phaseDuration()
        }
        sessionAudio.syncMusic(phase: phase, timerKind: timer?.timerKind ?? .study)
        sessionAudio.refreshVolumes()
        playedLastFourSecondCounterThisSegment = false
        updateUI()
        updateControlButton()
    }

    private func showFinish() {
        if !playedLastFourSecondCounterThisSegment {
            sessionAudio.playStartCounterTick()
        }
        hasReachedFinish = true
        countdownTimer?.invalidate()
        countdownTimer = nil
        isRunning = false
        sessionAudio.playTransitionSuccess()
        sessionAudio.stopMusicOnly()

        titleLabel.isHidden = true
        phaseIconImageView.isHidden = true
        stateEnglishLabel.isHidden = true
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
        let countDownPhase = phase == .start || phase == .focus || phase == .break_
        if isRunning && countDownPhase && !playedLastFourSecondCounterThisSegment && remainingSeconds == 4 {
            playedLastFourSecondCounterThisSegment = true
            sessionAudio.playStartCounterTick()
        }
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            advancePhase()
            return
        }
        if isRunning && countDownPhase && !playedLastFourSecondCounterThisSegment && remainingSeconds == 4 {
            playedLastFourSecondCounterThisSegment = true
            sessionAudio.playStartCounterTick()
        }
        sessionAudio.refreshVolumes()
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
        playedLastFourSecondCounterThisSegment = false
        sessionAudio.syncMusic(phase: phase, timerKind: timer?.timerKind ?? .study)
        sessionAudio.refreshVolumes()
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
