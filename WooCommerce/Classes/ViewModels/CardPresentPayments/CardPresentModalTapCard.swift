import UIKit

final class CardPresentModalTapCard: CardPresentPaymentsModalViewModel {
    private let name: String
    private let amount: String

    var topTitle: String {
        name
    }

    var topSubtitle: String {
        amount
    }

    let image: UIImage = .cardPresentImage

    let areButtonsVisible: Bool = false

    let primaryButtonTitle: String = ""

    let secondaryButtonTitle: String = ""

    let isAuxiliaryButtonHidden: Bool = true

    let auxiliaryButtonTitle: String = ""

    let bottomTitle: String = Localization.readerIsReady

    let bottomSubtitle: String = Localization.tapInsertOrSwipe

    init(name: String, amount: String) {
        self.name = name
        self.amount = amount
    }

    func didTapPrimaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        //
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        //
    }
}

private extension CardPresentModalTapCard {
    enum Localization {
        static let readerIsReady = NSLocalizedString(
            "Reader is ready",
            comment: "Indicates the status of a card reader. Presented to users when payment collection starts"
        )

        static let tapInsertOrSwipe = NSLocalizedString(
            "Tap, insert or swipe to pay",
            comment: "Label asking users to present a card. Presented to users when a payment is going to be collected"
        )
    }
}
