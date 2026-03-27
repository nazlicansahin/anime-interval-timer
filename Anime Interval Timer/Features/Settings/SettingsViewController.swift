import UIKit

final class SettingsViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let musicSlider = UISlider()
    private let counterSlider = UISlider()
    private let store = SoundSettingsStore.shared

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sound"
        navigationItem.largeTitleDisplayMode = .never

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let intro = UILabel()
        intro.text = "Adjust background music and countdown / transition sounds."
        intro.font = AppDesign.captionFont()
        intro.textColor = .secondaryLabel
        intro.numberOfLines = 0

        contentStack.addArrangedSubview(intro)
        contentStack.addArrangedSubview(makeSliderBlock(
            title: "Music volume",
            subtitle: "Break time & study focus background",
            slider: musicSlider,
            value: store.musicVolume
        ))
        contentStack.addArrangedSubview(makeSliderBlock(
            title: "Counter & SFX volume",
            subtitle: "Last seconds of start + success between phases",
            slider: counterSlider,
            value: store.counterSFXVolume
        ))

        musicSlider.addTarget(self, action: #selector(musicChanged), for: .valueChanged)
        counterSlider.addTarget(self, action: #selector(counterChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
    }

    private func makeSliderBlock(title: String, subtitle: String, slider: UISlider, value: Float) -> UIView {
        let wrap = UIView()
        let t = UILabel()
        t.text = title
        t.font = AppDesign.headlineFont()
        let s = UILabel()
        s.text = subtitle
        s.font = AppDesign.captionFont()
        s.textColor = .secondaryLabel
        s.numberOfLines = 0
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = value
        [t, s, slider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            wrap.addSubview($0)
        }
        NSLayoutConstraint.activate([
            t.topAnchor.constraint(equalTo: wrap.topAnchor),
            t.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            t.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            s.topAnchor.constraint(equalTo: t.bottomAnchor, constant: 4),
            s.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            s.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            slider.topAnchor.constraint(equalTo: s.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
        ])
        return wrap
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppAmbientMusicController.shared.ensureAmbientForNonTimerScreen()
    }

    @objc private func musicChanged() {
        store.musicVolume = musicSlider.value
        AppAmbientMusicController.shared.applyMusicVolumeFromSettings()
    }

    @objc private func counterChanged() {
        store.counterSFXVolume = counterSlider.value
    }
}
