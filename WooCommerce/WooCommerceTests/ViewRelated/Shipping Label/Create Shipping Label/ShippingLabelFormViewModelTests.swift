import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelFormViewModelTests: XCTestCase {

    func test_conversion_from_Address_to_ShippingLabelAddress_returns_correct_data() {

        // Given
        let address = Address(firstName: "Skylar",
                              lastName: "Ferry",
                              company: "Automattic Inc.",
                              address1: "60 29th Street #343",
                              address2: nil,
                              city: "San Francisco",
                              state: "CA",
                              postcode: "94121-2303",
                              country: "United States",
                              phone: nil,
                              email: nil)


        // When
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: address,
                                                                    destinationAddress: nil)

        // Then
        let originAddress = shippingLabelFormViewModel.originAddress

        XCTAssertEqual(originAddress?.company, "Automattic Inc.")
        XCTAssertEqual(originAddress?.name, "Skylar Ferry")
        XCTAssertEqual(originAddress?.phone, "")
        XCTAssertEqual(originAddress?.country, "United States")
        XCTAssertEqual(originAddress?.state, "CA")
        XCTAssertEqual(originAddress?.address1, "60 29th Street #343")
        XCTAssertEqual(originAddress?.address2, "")
        XCTAssertEqual(originAddress?.city, "San Francisco")
        XCTAssertEqual(originAddress?.postcode, "94121-2303")
    }

    func test_handleOriginAddressValueChanges_returns_updated_ShippingLabelAddress() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                           name: "Skylar Ferry",
                                                           phone: "12345",
                                                           country: "United States",
                                                           state: "CA",
                                                           address1: "60 29th",
                                                           address2: "Street #343",
                                                           city: "San Francisco",
                                                           postcode: "94121-2303")

        // When
        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.originAddress, expectedShippingAddress)
    }

    func test_handleDestinationAddressValueChanges_returns_updated_ShippingLabelAddress() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = ShippingLabelAddress(company: "Automattic Inc.",
                                                           name: "Skylar Ferry",
                                                           phone: "12345",
                                                           country: "United States",
                                                           state: "CA",
                                                           address1: "60 29th",
                                                           address2: "Street #343",
                                                           city: "San Francisco",
                                                           postcode: "94121-2303")

        // When
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.destinationAddress, expectedShippingAddress)
    }

    func test_handlePackageDetailsValueChanges_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPackageID = "my-package-id"
        let expectedPackageWeight = "55"

        // When
        shippingLabelFormViewModel.handlePackageDetailsValueChanges(selectedPackageID: expectedPackageID, totalPackageWeight: expectedPackageWeight)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.selectedPackageID, expectedPackageID)
        XCTAssertEqual(shippingLabelFormViewModel.totalPackageWeight, expectedPackageWeight)
    }

    func test_handleCarrierAndRatesValueChanges_returns_updated_data() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        XCTAssertNil(shippingLabelFormViewModel.selectedRate)
        XCTAssertNil(shippingLabelFormViewModel.selectedSignatureRate)
        XCTAssertNil(shippingLabelFormViewModel.selectedAdultSignatureRate)

        // When
        shippingLabelFormViewModel.handleCarrierAndRatesValueChanges(selectedRate: MockShippingLabelCarrierRate.makeRate(),
                                                                     selectedSignatureRate: MockShippingLabelCarrierRate.makeRate(title: "UPS"),
                                                                     selectedAdultSignatureRate: nil)

        // Then
        XCTAssertEqual(shippingLabelFormViewModel.selectedRate, MockShippingLabelCarrierRate.makeRate())
        XCTAssertEqual(shippingLabelFormViewModel.selectedSignatureRate, MockShippingLabelCarrierRate.makeRate(title: "UPS"))
        XCTAssertNil(shippingLabelFormViewModel.selectedAdultSignatureRate)
    }

    func test_sections_returns_updated_rows_after_validating_origin_address() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = MockShippingLabelAddress.sampleAddress()
        let currentRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[0].type, .shipFrom)
        XCTAssertEqual(currentRows?[0].dataState, .pending)
        XCTAssertEqual(currentRows?[0].displayMode, .editable)
        XCTAssertEqual(currentRows?[1].type, .shipTo)
        XCTAssertEqual(currentRows?[1].dataState, .pending)
        XCTAssertEqual(currentRows?[1].displayMode, .disabled)
        XCTAssertEqual(currentRows?[2].type, .packageDetails)
        XCTAssertEqual(currentRows?[2].dataState, .pending)
        XCTAssertEqual(currentRows?[2].displayMode, .disabled)

        // When

        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        let updatedRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(updatedRows?[0].type, .shipFrom)
        XCTAssertEqual(updatedRows?[0].dataState, .validated)
        XCTAssertEqual(updatedRows?[0].displayMode, .editable)
        XCTAssertEqual(updatedRows?[1].type, .shipTo)
        XCTAssertEqual(updatedRows?[1].dataState, .pending)
        XCTAssertEqual(updatedRows?[1].displayMode, .editable)
        XCTAssertEqual(updatedRows?[2].type, .packageDetails)
        XCTAssertEqual(updatedRows?[2].dataState, .pending)
        XCTAssertEqual(updatedRows?[2].displayMode, .disabled)
    }

    func test_sections_returns_updated_rows_after_validating_destination_address() {
        // Given
        let shippingLabelFormViewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedShippingAddress = MockShippingLabelAddress.sampleAddress()

        // When
        shippingLabelFormViewModel.handleOriginAddressValueChanges(address: expectedShippingAddress, validated: true)
        let currentRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[0].type, .shipFrom)
        XCTAssertEqual(currentRows?[0].dataState, .validated)
        XCTAssertEqual(currentRows?[0].displayMode, .editable)
        XCTAssertEqual(currentRows?[1].type, .shipTo)
        XCTAssertEqual(currentRows?[1].dataState, .pending)
        XCTAssertEqual(currentRows?[1].displayMode, .editable)
        XCTAssertEqual(currentRows?[2].type, .packageDetails)
        XCTAssertEqual(currentRows?[2].dataState, .pending)
        XCTAssertEqual(currentRows?[2].displayMode, .disabled)
        shippingLabelFormViewModel.handleDestinationAddressValueChanges(address: expectedShippingAddress, validated: true)

        // Then
        let updatedRows = shippingLabelFormViewModel.state.sections.first?.rows
        XCTAssertEqual(updatedRows?[0].type, .shipFrom)
        XCTAssertEqual(updatedRows?[0].dataState, .validated)
        XCTAssertEqual(updatedRows?[0].displayMode, .editable)
        XCTAssertEqual(updatedRows?[1].type, .shipTo)
        XCTAssertEqual(updatedRows?[1].dataState, .validated)
        XCTAssertEqual(updatedRows?[1].displayMode, .editable)
        XCTAssertEqual(updatedRows?[2].type, .packageDetails)
        XCTAssertEqual(updatedRows?[2].dataState, .pending)
        XCTAssertEqual(updatedRows?[2].displayMode, .editable)
    }

    func test_handlePaymentMethodValueChanges_returns_updated_data_and_state_with_no_selected_payment_method() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPaymentMethodID: Int64 = 0

        // When
        viewModel.handlePaymentMethodValueChanges(selectedPaymentMethodID: expectedPaymentMethodID, editable: false)

        // Then
        let currentRows = viewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[4].type, .paymentMethod)
        XCTAssertEqual(currentRows?[4].dataState, .pending)
        XCTAssertEqual(viewModel.selectedPaymentMethodID, expectedPaymentMethodID)
    }

    func test_handlePaymentMethodValueChanges_returns_updated_data_and_state_with_selected_payment_method() {
        // Given
        let viewModel = ShippingLabelFormViewModel(order: MockOrders().makeOrder(),
                                                                    originAddress: nil,
                                                                    destinationAddress: nil)
        let expectedPaymentMethodID: Int64 = 12345

        // When
        viewModel.handlePaymentMethodValueChanges(selectedPaymentMethodID: expectedPaymentMethodID, editable: false)

        // Then
        let currentRows = viewModel.state.sections.first?.rows
        XCTAssertEqual(currentRows?[4].type, .paymentMethod)
        XCTAssertEqual(currentRows?[4].dataState, .validated)
        XCTAssertEqual(viewModel.selectedPaymentMethodID, expectedPaymentMethodID)
    }
}
