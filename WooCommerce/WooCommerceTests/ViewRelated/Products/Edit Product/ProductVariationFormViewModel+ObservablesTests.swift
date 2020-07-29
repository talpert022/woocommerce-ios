import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for observables (`observableProduct`, `productName`, `isUpdateEnabled`)
final class ProductVariationFormViewModel_ObservablesTests: XCTestCase {
    private let defaultSiteID: Int64 = 134
    private var cancellableProduct: ObservationToken?
    private var cancellableProductName: ObservationToken?
    private var cancellableUpdateEnabled: ObservationToken?

    override func tearDown() {
        [cancellableProduct, cancellableProductName, cancellableUpdateEnabled].forEach { cancellable in
            cancellable?.cancel()
        }
        cancellableProduct = nil
        cancellableProductName = nil
        cancellableUpdateEnabled = nil

        super.tearDown()
    }

    func testProductVariationNameObservableIsNil() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)

        // Action
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation, productImageActionHandler: productImageActionHandler)

        // Assert
        XCTAssertNil(viewModel.productName)
    }

    func testObservablesAreNotEmittedFromEditActionsOfTheSameData() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation, productImageActionHandler: productImageActionHandler)
        cancellableProduct = viewModel.observableProduct.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { _ in
            // Assert
            XCTFail("Should not be triggered from edit actions of the same data")
        }

        // Action
        viewModel.updateImages(productVariation.images)
        viewModel.updateDescription(productVariation.description ?? "")
        viewModel.updatePriceSettings(regularPrice: productVariation.regularPrice,
                                      salePrice: productVariation.salePrice,
                                      dateOnSaleStart: productVariation.dateOnSaleStart,
                                      dateOnSaleEnd: productVariation.dateOnSaleEnd,
                                      taxStatus: productVariation.productTaxStatus,
                                      taxClass: nil)
        viewModel.updateInventorySettings(sku: productVariation.sku,
                                          manageStock: productVariation.manageStock,
                                          soldIndividually: nil,
                                          stockQuantity: productVariation.stockQuantity,
                                          backordersSetting: productVariation.backordersSetting,
                                          stockStatus: productVariation.stockStatus)
        viewModel.updateShippingSettings(weight: productVariation.weight, dimensions: productVariation.dimensions, shippingClass: nil)
    }

    func testObservablesFromUploadingAnImage() {
        // Arrange
        let productVariation = MockProductVariation().productVariation()
        let productImageActionHandler = ProductImageActionHandler(siteID: defaultSiteID, product: productVariation)
        let viewModel = ProductVariationFormViewModel(productVariation: productVariation, productImageActionHandler: productImageActionHandler)
        var isProductUpdated: Bool?
        cancellableProduct = viewModel.observableProduct.subscribe { product in
            isProductUpdated = true
        }

        var updatedProductName: String?
        cancellableProductName = viewModel.productName?.subscribe { productName in
            updatedProductName = productName
        }

        var updatedUpdateEnabled: Bool?
        let expectationForUpdateEnabled = self.expectation(description: "Update enabled updates")
        expectationForUpdateEnabled.expectedFulfillmentCount = 1
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { isUpdateEnabled in
            updatedUpdateEnabled = isUpdateEnabled
            expectationForUpdateEnabled.fulfill()
        }

        // Action
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: PHAsset())

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertNil(isProductUpdated)
        XCTAssertNil(updatedProductName)
        XCTAssertEqual(updatedUpdateEnabled, true)
    }
}
