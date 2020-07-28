import Yosemite

/// A view model for `ProductFormViewController` to add/edit a generic product model (e.g. `Product` or `ProductVariation`).
///
protocol ProductFormViewModelProtocol {
    associatedtype ProductModel: ProductFormDataModel & TaxClassRequestable

    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: Observable<ProductModel> { get }

    /// Emits product name on change. If product name is not editable, `nil` is returned.
    var productName: Observable<String>? { get }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> { get }

    /// Creates actions available on the bottom sheet.
    var actionsFactory: ProductFormActionsFactoryProtocol { get }

    /// The latest product value.
    var productModel: ProductModel { get }

    /// The latest product password, if the product is password protected.
    var password: String? { get }

    // Unsaved changes

    func hasUnsavedChanges() -> Bool

    func hasProductChanged() -> Bool

    func hasPasswordChanged() -> Bool

    func canViewProductInStore() -> Bool

    // Update actions

    func updateName(_ name: String)

    func updateImages(_ images: [ProductImage])

    func updateDescription(_ newDescription: String)

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?)

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Int64?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?)

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?)

    func updateProductCategories(_ categories: [ProductCategory])

    func updateProductTags(_ tags: [ProductTag])

    func updateBriefDescription(_ briefDescription: String)

    func updateSKU(_ sku: String?)

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64])

    func updateProductSettings(_ settings: ProductSettings)

    func updateExternalLink(externalURL: String?, buttonText: String)

    // Remote action

    func updateProductRemotely(onCompletion: @escaping (Result<ProductFormDataModel, ProductUpdateError>) -> Void)

    // Reset actions

    func resetPassword(_ password: String?)
}

/// Provides data for product form UI, and handles product editing actions.
final class ProductFormViewModel: ProductFormViewModelProtocol {
    typealias ProductModel = Product

    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: Observable<Product> {
        productSubject
    }

    /// Emits product name on change.
    var productName: Observable<String>? {
        productNameSubject
    }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> {
        isUpdateEnabledSubject
    }

    var productModel: Product {
        product
    }

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    private let productSubject: PublishSubject<Product> = PublishSubject<Product>()
    private let productNameSubject: PublishSubject<String> = PublishSubject<String>()
    private let isUpdateEnabledSubject: PublishSubject<Bool>

    /// The product model before any potential edits; reset after a remote update.
    private var originalProduct: Product {
        didSet {
            product = originalProduct
        }
    }

    /// The product model with potential edits; reset after a remote update.
    private var product: Product {
        didSet {
            guard product != oldValue else {
                return
            }

            defer {
                isUpdateEnabledSubject.send(hasUnsavedChanges())
            }

            if isNameTheOnlyChange(oldProduct: oldValue, newProduct: product) {
                productNameSubject.send(product.name)
                return
            }

            actionsFactory = ProductFormActionsFactory(product: product,
                                                                  isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                  isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
            productSubject.send(product)
        }
    }

    /// The product password, fetched in Product Settings
    private var originalPassword: String? {
        didSet {
            password = originalPassword
        }
    }

    private(set) var password: String? {
        didSet {
            if password != oldValue {
                isUpdateEnabledSubject.send(hasUnsavedChanges())
            }
        }
    }

    private let productImageActionHandler: ProductImageActionHandler
    private let isEditProductsRelease2Enabled: Bool
    private let isEditProductsRelease3Enabled: Bool

    private var cancellable: ObservationToken?

    init(product: Product,
         productImageActionHandler: ProductImageActionHandler,
         isEditProductsRelease2Enabled: Bool,
         isEditProductsRelease3Enabled: Bool) {
        self.productImageActionHandler = productImageActionHandler
        self.isEditProductsRelease2Enabled = isEditProductsRelease2Enabled
        self.isEditProductsRelease3Enabled = isEditProductsRelease3Enabled
        self.originalProduct = product
        self.product = product
        self.actionsFactory = ProductFormActionsFactory(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
        self.isUpdateEnabledSubject = PublishSubject<Bool>()

        self.cancellable = productImageActionHandler.addUpdateObserver(self) { [weak self] allStatuses in
            if allStatuses.productImageStatuses.hasPendingUpload {
                self?.isUpdateEnabledSubject.send(true)
            }
        }
    }

    deinit {
        cancellable?.cancel()
    }

    func hasUnsavedChanges() -> Bool {
        return product != originalProduct || productImageActionHandler.productImageStatuses.hasPendingUpload || password != originalPassword
    }

    func hasProductChanged() -> Bool {
        return product != originalProduct
    }

    func hasPasswordChanged() -> Bool {
        return password != nil && password != originalPassword
    }

    func canViewProductInStore() -> Bool {
        return originalProduct.productStatus == .publish
    }
}

// MARK: Action handling
//
extension ProductFormViewModel {
    func updateName(_ name: String) {
        product = product.copy(name: name)
    }

    func updateImages(_ images: [ProductImage]) {
        product = product.copy(images: images)
    }

    func updateDescription(_ newDescription: String) {
        product = product.copy(fullDescription: newDescription)
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        product = product.copy(dateOnSaleStart: dateOnSaleStart,
                               dateOnSaleEnd: dateOnSaleEnd,
                               regularPrice: regularPrice,
                               salePrice: salePrice,
                               taxStatusKey: taxStatus.rawValue,
                               taxClass: taxClass?.slug)
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool?,
                                 stockQuantity: Int64?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        product = product.copy(sku: sku,
                               manageStock: manageStock,
                               stockQuantity: stockQuantity,
                               stockStatusKey: stockStatus?.rawValue,
                               backordersKey: backordersSetting?.rawValue,
                               soldIndividually: soldIndividually)
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        product = product.copy(weight: weight,
                               dimensions: dimensions,
                               shippingClass: shippingClass?.slug ?? "",
                               shippingClassID: shippingClass?.shippingClassID ?? 0,
                               productShippingClass: shippingClass)
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        product = product.copy(categories: categories)
    }

    func updateProductTags(_ tags: [ProductTag]) {
        product = product.copy(tags: tags)
    }

    func updateBriefDescription(_ briefDescription: String) {
        product = product.copy(briefDescription: briefDescription)
    }

    func updateSKU(_ sku: String?) {
        product = product.copy(sku: sku)
    }

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64]) {
        product = product.copy(groupedProducts: groupedProductIDs)
    }

    func updateProductSettings(_ settings: ProductSettings) {
        product = product.copy(slug: settings.slug,
                               statusKey: settings.status.rawValue,
                               featured: settings.featured,
                               catalogVisibilityKey: settings.catalogVisibility.rawValue,
                               virtual: settings.virtual,
                               reviewsAllowed: settings.reviewsAllowed,
                               purchaseNote: settings.purchaseNote,
                               menuOrder: settings.menuOrder)
        password = settings.password
    }

    func updateExternalLink(externalURL: String?, buttonText: String) {
        product = product.copy(buttonText: buttonText, externalURL: externalURL)
    }
}

// MARK: Remote actions
//
extension ProductFormViewModel {
    func updateProductRemotely(onCompletion: @escaping (Result<ProductFormDataModel, ProductUpdateError>) -> Void) {
        let updateProductAction = ProductAction.updateProduct(product: product) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let product):
                self?.resetProduct(product)
                onCompletion(.success(product))
            }
        }
        ServiceLocator.stores.dispatch(updateProductAction)
    }
}

// MARK: Reset actions
//
extension ProductFormViewModel {
    private func resetProduct(_ product: ProductFormDataModel) {
        guard let product = product as? Product else {
            return
        }
        originalProduct = product
    }

    func resetPassword(_ password: String?) {
        originalPassword = password
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }
}

private extension ProductFormViewModel {
    func isNameTheOnlyChange(oldProduct: Product, newProduct: Product) -> Bool {
        let oldProductWithNewName = oldProduct.copy(name: newProduct.name)
        return oldProductWithNewName == newProduct && newProduct.name != oldProduct.name
    }
}
