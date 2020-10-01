import UIKit


/// Represents a cell with a Title Label and Body Label
///
final class HeadlineLabelTableViewCell: UITableViewCell {
    @IBOutlet private weak var headlineLabel: UILabel?
    @IBOutlet private weak var bodyLabel: UILabel?

    enum Style {
        /// Bold title with no margin against the body.
        case emphasized
        /// Normal body title with a margin against the body.
        case regular
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureHeadline()
        configureBody()
        apply(style: .emphasized)
    }

    func update(style: Style = .emphasized, headline: String?, body: String?) {
        headlineLabel?.text = headline
        bodyLabel?.text = body
    }
}


private extension HeadlineLabelTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureHeadline() {
        headlineLabel?.accessibilityIdentifier = "headline-label"
    }

    func configureBody() {
        bodyLabel?.accessibilityIdentifier = "body-label"
    }

    func apply(style: Style) {
        switch style {
        case .emphasized:
            headlineLabel?.applyHeadlineStyle()
            bodyLabel?.applyBodyStyle()
        case .regular:
            headlineLabel?.applyBodyStyle()
            bodyLabel?.applyBodyStyle()
        }
    }
}
