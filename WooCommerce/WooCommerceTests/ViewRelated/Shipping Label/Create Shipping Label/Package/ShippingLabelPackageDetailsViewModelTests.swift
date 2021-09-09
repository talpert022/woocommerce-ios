import XCTest
@testable import WooCommerce
import Yosemite
@testable import Storage

class ShippingLabelPackageDetailsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true))
    }

    override func tearDown() {
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    func test_foundMultiplePackages_returns_correctly() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageInfo(packageID: "Box 1", totalWeight: "12", productIDs: [1, 2, 3])
        let package2 = ShippingLabelPackageInfo(packageID: "Box 2", totalWeight: "5.5", productIDs: [1, 2, 3])

        // When & Then
        let viewModel1 = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [])
        XCTAssertFalse(viewModel1.foundMultiplePackages)

        let viewModel2 = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [package1])
        XCTAssertFalse(viewModel2.foundMultiplePackages)

        let viewModel3 = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [package1, package2])
        XCTAssertTrue(viewModel3.foundMultiplePackages)
    }

    func test_itemViewModels_returns_correctly_when_initial_selectedPackages_is_empty() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        insert(MockShippingLabelAccountSettings.sampleAccountSettings(siteID: sampleSiteID, lastSelectedPackageID: "package-1"))

        // When
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [], storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.itemViewModels.count, 1)
        XCTAssertEqual(viewModel.itemViewModels.first?.selectedPackageID, "package-1")
        XCTAssertEqual(viewModel.itemViewModels.first?.totalWeight, "0.0")
    }

    func test_itemViewModels_returns_correctly_when_initial_selectedPackages_is_not_empty() {
        // Given
        let orderItemAttributes = [OrderItemAttribute(metaID: 170, name: "Packaging", value: "Box")]
        let items = [MockOrderItem.sampleItem(name: "Easter Egg", productID: 1, quantity: 1),
                     MockOrderItem.sampleItem(name: "Jacket", productID: 33, quantity: 1),
                     MockOrderItem.sampleItem(name: "Italian Jacket", productID: 23, quantity: 2),
                     MockOrderItem.sampleItem(name: "Jeans",
                                              productID: 49,
                                              variationID: 49,
                                              quantity: 1,
                                              attributes: orderItemAttributes)]
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID, items: items)
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 1, virtual: false, weight: "123"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 33, virtual: true, weight: "9"))
        insert(Product.fake().copy(siteID: sampleSiteID, productID: 23, virtual: false, weight: "1"))
        insert(ProductVariation.fake().copy(siteID: sampleSiteID,
                                            productID: 49,
                                            productVariationID: 49,
                                            attributes: [ProductVariationAttribute(id: 1, name: "Color", option: "Blue")]))
        let package1 = ShippingLabelPackageInfo(packageID: "Box 1", totalWeight: "12", productIDs: [1, 33, 23])
        let package2 = ShippingLabelPackageInfo(packageID: "Box 2", totalWeight: "5.5", productIDs: [49])

        // When
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order,
                                                             packagesResponse: nil,
                                                             selectedPackages: [package1, package2],
                                                             storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.itemViewModels.count, 2)
        XCTAssertEqual(viewModel.itemViewModels.first?.selectedPackageID, package1.packageID)
        XCTAssertEqual(viewModel.itemViewModels.first?.totalWeight, package1.totalWeight)
        XCTAssertEqual(viewModel.itemViewModels.first?.itemsRows.count, 3)
        XCTAssertEqual(viewModel.itemViewModels.last?.selectedPackageID, package2.packageID)
        XCTAssertEqual(viewModel.itemViewModels.last?.totalWeight, package2.totalWeight)
        XCTAssertEqual(viewModel.itemViewModels.last?.itemsRows.count, 1)
    }

    func test_doneButtonEnabled_returns_true_when_all_packages_are_valid() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageInfo(packageID: "Box 1", totalWeight: "12", productIDs: [1, 2, 3])
        let package2 = ShippingLabelPackageInfo(packageID: "Box 2", totalWeight: "5.5", productIDs: [1, 2, 3])

        // When
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [package1, package2])

        // Then
        XCTAssertTrue(viewModel.doneButtonEnabled)
    }

    func test_doneButtonEnabled_returns_false_when_not_all_packages_are_valid() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageInfo(packageID: "Box 1", totalWeight: "12", productIDs: [1, 2, 3])
        let package2 = ShippingLabelPackageInfo(packageID: "Box 2", totalWeight: "5.5", productIDs: [1, 2, 3])

        // When
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [package1, package2])
        viewModel.itemViewModels.first?.totalWeight = "0"

        // Then
        XCTAssertFalse(viewModel.doneButtonEnabled)
    }

    func test_validatedPackages_returns_correctly() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageInfo(packageID: "Box 1", totalWeight: "12", productIDs: [1, 2, 3])
        let package2 = ShippingLabelPackageInfo(packageID: "Box 2", totalWeight: "5.5", productIDs: [1, 2, 3])

        // When
        let viewModel = ShippingLabelPackageDetailsViewModel(order: order, packagesResponse: nil, selectedPackages: [package1, package2])

        // Then
        XCTAssertEqual(viewModel.validatedPackages.count, 2)
        XCTAssertEqual(viewModel.validatedPackages.first?.packageID, package1.packageID)
        XCTAssertEqual(viewModel.validatedPackages.last?.packageID, package2.packageID)
    }
}

// MARK: - Utils
private extension ShippingLabelPackageDetailsViewModelTests {
    func insert(_ readOnlyOrderProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyOrderProduct)
    }

    func insert(_ readOnlyOrderProductVariation: Yosemite.ProductVariation) {
        let productVariation = storage.insertNewObject(ofType: StorageProductVariation.self)
        productVariation.update(with: readOnlyOrderProductVariation)
    }

    func insert(_ readOnlyAccountSettings: Yosemite.ShippingLabelAccountSettings) {
        let accountSettings = storage.insertNewObject(ofType: StorageShippingLabelAccountSettings.self)
        accountSettings.update(with: readOnlyAccountSettings)
    }
}
