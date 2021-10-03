import XCTest
@testable import WooCommerce
@testable import CocoaLumberjack
@testable import Hardware

final class ServiceLocatorTests: XCTestCase {

    func test_ServiceLocator_provides_analytics() {
        XCTAssertNotNil(ServiceLocator.analytics)
    }

    func test_analytics_defaults_to_WooAnalytics() {
        let analytics = ServiceLocator.analytics

        XCTAssertTrue(analytics is WooAnalytics)
    }

    func test_ServiceLocator_provides_stores() {
        XCTAssertNotNil(ServiceLocator.stores)
    }

    func test_stores_defaults_to_DefaultStoresManager() {
        let stores = ServiceLocator.stores

        XCTAssertTrue(stores is DefaultStoresManager)
    }

    func test_ServiceLocator_provides_notices() {
        XCTAssertNotNil(ServiceLocator.noticePresenter)
    }

    func test_notices_defaults_to_NoticePresenter() {
        let notices = ServiceLocator.noticePresenter

        XCTAssertTrue((notices as Any) is NoticePresenter)
    }

    func test_ServiceLocator_provides_pushNotificationsManager() {
        XCTAssertNotNil(ServiceLocator.pushNotesManager)
    }

    func test_ServiceLocator_provides_authenticationManager() {
        XCTAssertNotNil(ServiceLocator.authenticationManager)
    }

    func test_autenticationManager_defaults_to_AuthenticationManager() {
        let authentication = ServiceLocator.authenticationManager

        XCTAssertTrue(authentication is AuthenticationManager)
    }

    func test_ServiceLocator_provides_shippingSettingsService() {
        XCTAssertNotNil(ServiceLocator.shippingSettingsService)
    }

    func test_ServiceLocator_provides_currencySettings() {
        XCTAssertNotNil(ServiceLocator.currencySettings)
    }

    func test_ServiceLocator_provides_selectedSiteSettings() {
        XCTAssertNotNil(ServiceLocator.selectedSiteSettings)
    }

    func test_ServiceLocator_provides_storageManager() {
        XCTAssertNotNil(ServiceLocator.storageManager)
    }

    func test_ServiceLocator_provides_fileLogger() {
        XCTAssertNotNil(ServiceLocator.fileLogger)
    }

    func test_ServiceLocator_provides_keyboardStateProvider() {
        XCTAssertNotNil(ServiceLocator.keyboardStateProvider)
        XCTAssertTrue(ServiceLocator.keyboardStateProvider is KeyboardStateProvider)
    }

    func test_fileLogger_defaults_to_DDFileLogger() {
        let fileLogger = ServiceLocator.fileLogger

        XCTAssertTrue(fileLogger is DDFileLogger)
    }

    func test_ServiceLocator_provides_card_reader() {
       XCTAssertNotNil(ServiceLocator.cardReaderService)
   }

    func test_card_reader_service_defaults_to_Stripe() {
       let cardReader = ServiceLocator.cardReaderService

        XCTAssertTrue(cardReader is StripeCardReaderService)
   }

    func test_ServiceLocator_provides_receipt_printer() {
       XCTAssertNotNil(ServiceLocator.receiptPrinterService)
   }

    func test_receipt_printer_service_defaults_to_airprint() {
       let cardReader = ServiceLocator.receiptPrinterService

        XCTAssertTrue(cardReader is AirPrintReceiptPrinterService)
   }

    func test_ServiceLocator_provides_crash_logging() {
        XCTAssertNotNil(ServiceLocator.crashLogging)
    }

    func test_crash_logging_defaults_to_woo_crash_logging() {
        let crashLogging = ServiceLocator.crashLogging
        XCTAssertTrue(crashLogging is WooCrashLoggingStack)

    }
}
