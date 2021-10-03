import UITestsFoundation
import XCTest
import XCUITestHelpers

private struct ElementStringIDs {
    static let passwordTextField = "Password"
    static let loginButton = "Password Next Button"
    static let errorLabel = "pswdErrorLabel"
}

final class LoginPasswordScreen: BaseScreen {
    private let passwordTextField: XCUIElement
    private let loginButton: XCUIElement

    init() {
        passwordTextField = XCUIApplication().secureTextFields[ElementStringIDs.passwordTextField]
        loginButton = XCUIApplication().buttons[ElementStringIDs.loginButton]
        super.init(element: passwordTextField)

        XCTAssert(passwordTextField.waitForExistence(timeout: 3))
    }

    func proceedWith(password: String) -> LoginEpilogueScreen {
        _ = tryProceed(password: password)

        return LoginEpilogueScreen()
    }

    func tryProceed(password: String) -> LoginPasswordScreen {
        XCTAssert(passwordTextField.waitForIsHittable(timeout: 3))

        passwordTextField.paste(text: password)

        XCTAssert(loginButton.waitForExistence(timeout: 3))
        XCTAssert(loginButton.waitForIsHittable(timeout: 3))

        loginButton.tap()

        return self
    }

    func verifyLoginError() -> LoginPasswordScreen {
        let errorLabel = app.staticTexts[ElementStringIDs.errorLabel]
        _ = errorLabel.waitForExistence(timeout: 2)

        XCTAssert(errorLabel.waitForExistence(timeout: 3))
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.loginButton].exists
    }
}
