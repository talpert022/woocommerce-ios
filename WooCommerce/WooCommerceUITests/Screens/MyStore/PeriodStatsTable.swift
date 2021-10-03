import UITestsFoundation
import XCTest

final class PeriodStatsTable: BaseScreen {

    struct ElementStringIDs {
        static let daysTab = "period-data-today-tab"
        static let weeksTab = "period-data-thisWeek-tab"
        static let monthsTab = "period-data-thisMonth-tab"
        static let yearsTab = "period-data-thisYear-tab"
    }


    private let daysTab = XCUIApplication().cells[ElementStringIDs.daysTab]
    private let weeksTab = XCUIApplication().cells[ElementStringIDs.weeksTab]
    private let monthsTab = XCUIApplication().cells[ElementStringIDs.monthsTab]
    private let yearsTab = XCUIApplication().cells[ElementStringIDs.yearsTab]

    init() {

        super.init(element: daysTab)

        XCTAssert(daysTab.waitForExistence(timeout: 3))
        XCTAssert(weeksTab.waitForExistence(timeout: 3))
        XCTAssert(monthsTab.waitForExistence(timeout: 3))
        XCTAssert(yearsTab.waitForExistence(timeout: 3))
    }

    @discardableResult
    func switchToDaysTab() -> Self {
        daysTab.tap()
        return self
    }

    @discardableResult
       func switchToWeeksTab() -> Self {
           weeksTab.tap()
           return self
       }

    @discardableResult
    func switchToYearsTab() -> Self {
        yearsTab.tap()
        return self
    }

    static func isLoaded() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.daysTab].exists
    }

    static func isVisible() -> Bool {
        return XCUIApplication().buttons[ElementStringIDs.daysTab].isHittable
    }
}
