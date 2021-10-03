import XCTest

open class BaseScreen {

    enum UITestError: Error {
        case unableToLocateElement
    }

    public private(set) var app: XCUIApplication!
    var expectedElement: XCUIElement!
    var waitTimeout: Double!

    public init(element: XCUIElement) {
        app = XCUIApplication()
        expectedElement = element
        waitTimeout = 20
        try! waitForPage()
    }

    @discardableResult
    func waitForPage() throws -> BaseScreen {
        XCTContext.runActivity(named: "Confirm page \(self) is loaded") { (activity) in
            let result = waitFor(element: expectedElement, predicate: "isEnabled == true", timeout: 20)
            XCTAssert(result, "Page \(self) is not loaded.")
        }
        return self
    }

    @discardableResult
    public func waitFor(element: XCUIElement, predicate: String, timeout: Int? = nil) -> Bool {
        let timeoutValue = timeout ?? 5

        let elementPredicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        let result = XCTWaiter.wait(for: [elementPredicate], timeout: TimeInterval(timeoutValue))

        return result == .completed
    }

    func isLoaded() -> Bool {
        return expectedElement.exists
    }

    /// Scroll an element into view within another element.
    /// scrollView can be a UIScrollView, or anything that subclasses it like UITableView
    ///
    /// TODO: The implementation of this could use work:
    /// - What happens if the element is above the current scroll view position?
    /// - What happens if it's a really long scroll view?

    public func scrollElementIntoView(element: XCUIElement, within scrollView: XCUIElement, threshold: Int = 1000) {

        var iteration = 0

        while !element.isFullyVisibleOnScreen && iteration < threshold {
            scrollView.scroll(byDeltaX: 0, deltaY: 100)
            iteration += 1
        }

        if !element.isFullyVisibleOnScreen {
            XCTFail("Unable to scroll element into view")
        }
    }

    // Pops the navigation stack, returning to the item above the current one
    public func pop() {
        navBackButton.tap()
    }

    func then(_ block: () -> Void) -> Self {
        block()
        return self
    }

    /// This would be way nicer if we could base `Self` as the type of object to the block
    public func then(_ block: (BaseScreen) -> Void) -> Self {
        block(self)
        return self
    }
}

private extension XCUIElement {
    var isFullyVisibleOnScreen: Bool {
        guard self.exists && !self.frame.isEmpty && self.isHittable else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
}

private extension XCUIElementAttributes {
    var isNetworkLoadingIndicator: Bool {
        if hasWhiteListedIdentifier { return false }

        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.isBetween(46, and: 47) && frame.size.height.isBetween(2, and: 3)

        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasWhiteListedIdentifier: Bool {
        let whiteListedIdentifiers = ["GeofenceLocationTrackingOn", "StandardLocationTrackingOn"]

        return whiteListedIdentifiers.contains(identifier)
    }

    func isStatusBar(_ deviceWidth: CGFloat) -> Bool {
        if elementType == .statusBar { return true }
        guard frame.origin == .zero else { return false }

        let oldStatusBarSize = CGSize(width: deviceWidth, height: 20)
        let newStatusBarSize = CGSize(width: deviceWidth, height: 44)

        return [oldStatusBarSize, newStatusBarSize].contains(frame.size)
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isNetworkLoadingIndicator
        }

        return self.containing(isNetworkLoadingIndicator)
    }
}

private extension CGFloat {
    func isBetween(_ numberA: CGFloat, and numberB: CGFloat) -> Bool {
        return numberA...numberB ~= self
    }
}
