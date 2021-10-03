import UITestsFoundation
import XCTest

private struct ElementStringIDs {
    static let navBar = "WordPressAuthenticator.LoginSelfHostedView"
    static let usernameTextField = "usernameField"
    static let passwordTextField = "passwordField"
    static let nextButton = "submitButton"
}

final class LoginUsernamePasswordScreen: BaseScreen {
    private let navBar: XCUIElement
    private let usernameTextField: XCUIElement
    private let passwordTextField: XCUIElement
    private let nextButton: XCUIElement

    init() {
        let app = XCUIApplication()
        navBar = app.navigationBars[ElementStringIDs.navBar]
        usernameTextField = app.textFields[ElementStringIDs.usernameTextField]
        passwordTextField = app.secureTextFields[ElementStringIDs.passwordTextField]
        nextButton = app.buttons[ElementStringIDs.nextButton]

        super.init(element: passwordTextField)
    }

    func proceedWith(username: String, password: String) -> LoginEpilogueScreen {
        usernameTextField.tap()
        usernameTextField.typeText(username)
        passwordTextField.tap()
        passwordTextField.typeText(password)
        nextButton.tap()

        return LoginEpilogueScreen()
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.nextButton].exists
    }
}
