import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let passwordOption = "Use Password"
    static let linkButton = "Send Link Button"
}

final class LinkOrPasswordScreen: BaseScreen {
    private let passwordOption: XCUIElement
    private let linkButton: XCUIElement

    init() {
        passwordOption = XCUIApplication().buttons[ElementStringIDs.passwordOption]
        linkButton = XCUIApplication().buttons[ElementStringIDs.linkButton]

        super.init(element: passwordOption)
    }

    func proceedWithPassword() -> LoginPasswordScreen {
        passwordOption.tap()

        return LoginPasswordScreen()
    }

    func proceedWithLink() -> LoginCheckMagicLinkScreen {
        linkButton.tap()

        return LoginCheckMagicLinkScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.passwordOption].exists
    }
}
