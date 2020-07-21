import Yosemite

/// Provides data for product form UI on a ProductVariation, and handles product editing actions.
final class ProductVariationFormViewModel: ProductFormViewModelProtocol {
    /// Emits product on change, except when the product name is the only change (`productName` is emitted for this case).
    var observableProduct: Observable<ProductFormDataModel> {
        productSubject
    }

    var productValue: ProductFormDataModel {
        productVariation
    }

    /// Emits product name on change.
    var productName: Observable<String> {
        productNameSubject
    }

    /// Emits a boolean of whether the product has unsaved changes for remote update.
    var isUpdateEnabled: Observable<Bool> {
        isUpdateEnabledSubject
    }

    /// Creates actions available on the bottom sheet.
    private(set) var actionsFactory: ProductFormActionsFactoryProtocol

    private let productSubject: PublishSubject<ProductFormDataModel> = PublishSubject<ProductFormDataModel>()
    private let productNameSubject: PublishSubject<String> = PublishSubject<String>()
    private let isUpdateEnabledSubject: PublishSubject<Bool>

    /// The product model before any potential edits; reset after a remote update.
    private var originalProductVariation: ProductVariation {
        didSet {
            productVariation = originalProductVariation
        }
    }

    /// The product model with potential edits; reset after a remote update.
    private var productVariation: ProductVariation {
        didSet {
            guard productVariation != oldValue else {
                return
            }

            defer {
                isUpdateEnabledSubject.send(hasUnsavedChanges())
            }

            actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation)
            productSubject.send(productVariation)
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

    private var cancellable: ObservationToken?

    init(productVariation: ProductVariation,
         productImageActionHandler: ProductImageActionHandler) {
        self.productImageActionHandler = productImageActionHandler
        self.originalProductVariation = productVariation
        self.productVariation = productVariation
        self.actionsFactory = ProductVariationFormActionsFactory(productVariation: productVariation)
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
        return productVariation != originalProductVariation || productImageActionHandler.productImageStatuses.hasPendingUpload || password != originalPassword
    }

    func hasProductChanged() -> Bool {
        return productVariation != originalProductVariation
    }

    func hasPasswordChanged() -> Bool {
        return password != nil && password != originalPassword
    }

    func canViewProductInStore() -> Bool {
        // no-op
        return false
//        return originalProduct.productStatus == .publish
    }
}

// MARK: Action handling
//
extension ProductVariationFormViewModel {
    func updateName(_ name: String) {
        // no-op
//        productVariation = productVariation.copy(name: name)
    }

    func updateImages(_ images: [ProductImage]) {
        // TODO-jc
        if images.count > 1 {
            // TODO-jc: Log error
        }
        productVariation = productVariation.copy(image: images.first)
    }

    func updateDescription(_ newDescription: String) {
        // TODO-jc
        productVariation = productVariation.copy(description: newDescription)
    }

    func updatePriceSettings(regularPrice: String?,
                             salePrice: String?,
                             dateOnSaleStart: Date?,
                             dateOnSaleEnd: Date?,
                             taxStatus: ProductTaxStatus,
                             taxClass: TaxClass?) {
        productVariation = productVariation.copy(dateOnSaleStart: dateOnSaleStart,
                                                 dateOnSaleEnd: dateOnSaleEnd,
                                                 regularPrice: regularPrice,
                                                 salePrice: salePrice,
                                                 taxStatusKey: taxStatus.rawValue,
                                                 taxClass: taxClass?.slug)
    }

    func updateInventorySettings(sku: String?,
                                 manageStock: Bool,
                                 soldIndividually: Bool,
                                 stockQuantity: Int64?,
                                 backordersSetting: ProductBackordersSetting?,
                                 stockStatus: ProductStockStatus?) {
        // TODO-jc: update inventory UI to remove `soldIndividually`
        productVariation = productVariation.copy(sku: sku,
                                                 manageStock: manageStock,
                                                 stockQuantity: stockQuantity,
                                                 stockStatus: stockStatus,
                                                 backordersKey: backordersSetting?.rawValue)
    }

    func updateShippingSettings(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        productVariation = productVariation.copy(weight: weight,
                                                 dimensions: dimensions,
                                                 shippingClass: shippingClass?.slug ?? "",
                                                 shippingClassID: shippingClass?.shippingClassID ?? 0)
    }

    func updateProductCategories(_ categories: [ProductCategory]) {
        // no-op
    }

    func updateProductTags(_ tags: [ProductTag]) {
        // no-op
    }

    func updateBriefDescription(_ briefDescription: String) {
        // no-op
    }

    func updateSKU(_ sku: String?) {
        // no-op
    }

    func updateGroupedProductIDs(_ groupedProductIDs: [Int64]) {
        // no-op
    }

    func updateProductSettings(_ settings: ProductSettings) {
        // no-op
    }

    func updateExternalLink(externalURL: String?, buttonText: String) {
        // no-op
    }
}

// MARK: Reset actions
//
extension ProductVariationFormViewModel {
    func updateProductRemotely(onCompletion: @escaping (Result<ProductFormDataModel, ProductUpdateError>) -> Void) {
        // TODO-jc
    }
}

// MARK: Reset actions
//
extension ProductVariationFormViewModel {
    private func resetProduct(_ product: ProductFormDataModel) {
        guard let productVariation = product as? ProductVariation else {
            return
        }
        originalProductVariation = productVariation
    }

    func resetPassword(_ password: String?) {
        originalPassword = password
        isUpdateEnabledSubject.send(hasUnsavedChanges())
    }
}
