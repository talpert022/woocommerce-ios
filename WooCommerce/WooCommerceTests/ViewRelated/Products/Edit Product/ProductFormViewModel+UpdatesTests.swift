import Photos
import XCTest

@testable import WooCommerce
import Yosemite

/// Unit tests for update functions in `ProductFormViewModel`.
final class ProductFormViewModel_UpdatesTests: XCTestCase {
    func testUpdatingName() {
        // Arrange
        let product = MockProduct().product(name: "Test")
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newName = "<p> cool product </p>"
        viewModel.updateName(newName)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.name, newName)
    }

    func testUpdatingDescription() {
        // Arrange
        let product = MockProduct().product(fullDescription: "Test")
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newDescription = "<p> cool product </p>"
        viewModel.updateDescription(newDescription)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.fullDescription, newDescription)
    }

    func testUpdatingShippingSettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newWeight = "9999.88"
        let newDimensions = ProductDimensions(length: "122", width: "333", height: "")
        let newShippingClass = ProductShippingClass(count: 2020,
                                                    descriptionHTML: "Arriving in 2 days!",
                                                    name: "2 Days",
                                                    shippingClassID: 2022,
                                                    siteID: product.siteID,
                                                    slug: "2-days")
        viewModel.updateShippingSettings(weight: newWeight, dimensions: newDimensions, shippingClass: newShippingClass)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.fullDescription, product.fullDescription)
        XCTAssertEqual((viewModel.productValue as? Product)?.name, product.name)
        XCTAssertEqual((viewModel.productValue as? Product)?.weight, newWeight)
        XCTAssertEqual((viewModel.productValue as? Product)?.dimensions, newDimensions)
        XCTAssertEqual((viewModel.productValue as? Product)?.shippingClass, newShippingClass.slug)
        XCTAssertEqual((viewModel.productValue as? Product)?.shippingClassID, newShippingClass.shippingClassID)
        XCTAssertEqual((viewModel.productValue as? Product)?.productShippingClass, newShippingClass)
    }

    func testUpdatingPriceSettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newRegularPrice = "32.45"
        let newSalePrice = "20.00"
        let newDateOnSaleStart = Date()
        let newDateOnSaleEnd = newDateOnSaleStart.addingTimeInterval(86400)
        let newTaxStatus = ProductTaxStatus.taxable
        let newTaxClass = TaxClass(siteID: product.siteID, name: "Reduced rate", slug: "reduced-rate")
        viewModel.updatePriceSettings(regularPrice: newRegularPrice,
                                      salePrice: newSalePrice,
                                      dateOnSaleStart: newDateOnSaleStart,
                                      dateOnSaleEnd: newDateOnSaleEnd,
                                      taxStatus: newTaxStatus,
                                      taxClass: newTaxClass)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.regularPrice, newRegularPrice)
        XCTAssertEqual((viewModel.productValue as? Product)?.salePrice, newSalePrice)
        XCTAssertEqual((viewModel.productValue as? Product)?.dateOnSaleStart, newDateOnSaleStart)
        XCTAssertEqual((viewModel.productValue as? Product)?.dateOnSaleEnd, newDateOnSaleEnd)
        XCTAssertEqual((viewModel.productValue as? Product)?.taxStatusKey, newTaxStatus.rawValue)
        XCTAssertEqual((viewModel.productValue as? Product)?.taxClass, newTaxClass.slug)
    }

    func testUpdatingInventorySettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newSKU = "94115"
        let newManageStock = !product.manageStock
        let newSoldIndividually = !product.soldIndividually
        let newStockQuantity: Int64 = 17
        let newBackordersSetting = ProductBackordersSetting.allowedAndNotifyCustomer
        let newStockStatus = ProductStockStatus.onBackOrder
        viewModel.updateInventorySettings(sku: newSKU,
                                          manageStock: newManageStock,
                                          soldIndividually: newSoldIndividually,
                                          stockQuantity: newStockQuantity,
                                          backordersSetting: newBackordersSetting,
                                          stockStatus: newStockStatus)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.sku, newSKU)
        XCTAssertEqual((viewModel.productValue as? Product)?.manageStock, newManageStock)
        XCTAssertEqual((viewModel.productValue as? Product)?.soldIndividually, newSoldIndividually)
        XCTAssertEqual((viewModel.productValue as? Product)?.stockQuantity, newStockQuantity)
        XCTAssertEqual((viewModel.productValue as? Product)?.backordersSetting, newBackordersSetting)
        XCTAssertEqual((viewModel.productValue as? Product)?.productStockStatus, newStockStatus)
    }

    func testUpdatingImages() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newImage = ProductImage(imageID: 17,
                                    dateCreated: date(with: "2018-01-26T21:49:45"),
                                    dateModified: date(with: "2018-01-26T21:50:11"),
                                    src: "https://somewebsite.com/shirt.jpg",
                                    name: "Tshirt",
                                    alt: "")
        let newImages = [newImage]
        viewModel.updateImages(newImages)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.images, newImages)
    }

    func testUpdatingProductCategories() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: true)

        // Action
        let categoryID = Int64(1234)
        let parentID = Int64(1)
        let name = "Test category"
        let slug = "test-category"
        let newCategories = [ProductCategory(categoryID: categoryID, siteID: product.siteID, parentID: parentID, name: name, slug: slug)]
        viewModel.updateProductCategories(newCategories)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.categories, newCategories)
    }

    func testUpdatingProductTags() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: true)

        // Action
        let tagID = Int64(1234)
        let name = "Test tag"
        let slug = "test-tag"
        let newTags = [ProductTag(siteID: 0, tagID: tagID, name: name, slug: slug)]
        viewModel.updateProductTags(newTags)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.tags, newTags)
    }

    func testUpdatingBriefDescription() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newBriefDescription = "<p> deal of the day! </p>"
        viewModel.updateBriefDescription(newBriefDescription)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.briefDescription, newBriefDescription)
    }

    func testUpdatingProductSettings() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let newStatus = "pending"
        let featured = true
        let password = ""
        let catalogVisibility = "search"
        let virtual = true
        let reviewsAllowed = true
        let slug = "this-is-a-test"
        let purchaseNote = "This is a purchase note"
        let menuOrder = 0
        let productSettings = ProductSettings(status: .pending,
                                              featured: featured,
                                              password: password,
                                              catalogVisibility: .search,
                                              virtual: virtual,
                                              reviewsAllowed: reviewsAllowed,
                                              slug: slug,
                                              purchaseNote: purchaseNote,
                                              menuOrder: menuOrder)
        viewModel.updateProductSettings(productSettings)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.statusKey, newStatus)
        XCTAssertEqual((viewModel.productValue as? Product)?.featured, featured)
        XCTAssertEqual((viewModel.productValue as? Product)?.catalogVisibilityKey, catalogVisibility)
        XCTAssertEqual((viewModel.productValue as? Product)?.reviewsAllowed, reviewsAllowed)
        XCTAssertEqual((viewModel.productValue as? Product)?.slug, slug)
        XCTAssertEqual((viewModel.productValue as? Product)?.purchaseNote, purchaseNote)
        XCTAssertEqual((viewModel.productValue as? Product)?.menuOrder, menuOrder)
    }

    func testUpdatingSKU() {
        // Arrange
        let product = MockProduct().product(sku: "")
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let sku = "woooo"
        viewModel.updateSKU(sku)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.sku, sku)
    }

    func testUpdatingExternalLink() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let externalURL = "woo.com"
        let buttonText = "Try!"
        viewModel.updateExternalLink(externalURL: externalURL, buttonText: buttonText)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.externalURL, externalURL)
        XCTAssertEqual((viewModel.productValue as? Product)?.buttonText, buttonText)
    }

    func testUpdatingGroupedProductIDs() {
        // Arrange
        let product = MockProduct().product()
        let productImageActionHandler = ProductImageActionHandler(siteID: 0, product: product)
        let viewModel = ProductFormViewModel(product: product,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease2Enabled: true,
                                             isEditProductsRelease3Enabled: false)

        // Action
        let groupedProductIDs: [Int64] = [630, 22]
        viewModel.updateGroupedProductIDs(groupedProductIDs)

        // Assert
        XCTAssertEqual((viewModel.productValue as? Product)?.groupedProducts, groupedProductIDs)
    }
}

private extension ProductFormViewModel_UpdatesTests {
    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
