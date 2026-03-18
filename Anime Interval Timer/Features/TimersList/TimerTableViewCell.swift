import UIKit

final class TimerTableViewCell: UITableViewCell {

    @IBOutlet private weak var emojiLabel: UILabel?
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var loopsLabel: UILabel?

    @IBOutlet private weak var startValueLabel: UILabel?
    @IBOutlet private weak var focusValueLabel: UILabel?
    @IBOutlet private weak var breakValueLabel: UILabel?

    @IBOutlet private weak var deleteButton: UIButton?
    @IBOutlet private weak var startButton: UIButton?

    var onTapDelete: (() -> Void)?
    var onTapStart: (() -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapDelete = nil
        onTapStart = nil
    }

    func configure(with display: TimersListViewModel.DisplayTimer) {
        emojiLabel?.text = display.emoji
        titleLabel?.text = display.title
        loopsLabel?.text = display.loopsText ?? ""
        loopsLabel?.isHidden = (display.loopsText == nil)

        startValueLabel?.text = display.startText
        focusValueLabel?.text = display.focusText
        breakValueLabel?.text = display.breakText
    }

    @IBAction private func deleteTapped(_ sender: UIButton) {
        onTapDelete?()
    }

    @IBAction private func startTapped(_ sender: UIButton) {
        onTapStart?()
    }
}

