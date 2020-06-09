import Foundation
import Networking
import Storage

enum DefaultError: Error {
    case unknown
}


// MARK: - ProductStore
//
public class ProductStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductAction else {
            assertionFailure("ProductStore received an unsupported action")
            return
        }

        switch action {
        case .resetStoredProducts(let onCompletion):
            resetStoredProducts(onCompletion: onCompletion)
        case .retrieveProduct(let siteID, let productID, let onCompletion):
            retrieveProduct(siteID: siteID, productID: productID, onCompletion: onCompletion)
        case .retrieveProducts(let siteID, let productIDs, let onCompletion):
            retrieveProducts(siteID: siteID, productIDs: productIDs, onCompletion: onCompletion)
        case .searchProducts(let siteID, let keyword, let pageNumber, let pageSize, let onCompletion):
            searchProducts(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .searchProductBySKU(let siteID, let sku, let onCompletion):
            searchProductBySKU(siteID: siteID, sku: sku, onCompletion: onCompletion)
        case .synchronizeProducts(let siteID,
                                  let pageNumber,
                                  let pageSize,
                                  let stockStatus,
                                  let productStatus,
                                  let productType,
                                  let sortOrder,
                                  let onCompletion):
            synchronizeProducts(siteID: siteID,
                                pageNumber: pageNumber,
                                pageSize: pageSize,
                                stockStatus: stockStatus,
                                productStatus: productStatus,
                                productType: productType,
                                sortOrder: sortOrder,
                                onCompletion: onCompletion)
        case .requestMissingProducts(let order, let onCompletion):
            requestMissingProducts(for: order, onCompletion: onCompletion)
        case .updateProduct(let product, let onCompletion):
            updateProduct(product: product, onCompletion: onCompletion)
        case .validateProductSKU(let sku, let siteID, let onCompletion):
            validateProductSKU(sku, siteID: siteID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductStore {

    /// Deletes all of the Stored Products.
    ///
    func resetStoredProducts(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.Product.self)
        storage.saveIfNeeded()
        DDLogDebug("Products deleted")

        onCompletion()
    }

    /// Searches all of the products that contain a given Keyword.
    ///
    func searchProducts(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductsRemote(network: network)
        remote.searchProducts(for: siteID,
                              keyword: keyword,
                              pageNumber: pageNumber,
                              pageSize: pageSize) { [weak self] (products, error) in
                                guard let products = products else {
                                    onCompletion(error)
                                    return
                                }

                                self?.upsertSearchResultsInBackground(siteID: siteID,
                                                                      keyword: keyword,
                                                                      readOnlyProducts: products) {
                                    onCompletion(nil)
                                }
        }
    }

    /// Searches all of the products that contain a given SKU.
    ///
    func searchProductBySKU(siteID: Int64, sku: String, onCompletion: @escaping (Result<Product, Error>) -> Void) {
        let remote = ProductsRemote(network: network)
        remote.searchProductsBySKU(for: siteID,
                                   sku: sku) { [weak self] (products, error) in
                                    guard let products = products, let product = products.first else {
                                        onCompletion(.failure(error ?? DefaultError.unknown))
                                        return
                                    }

                                    self?.upsertStoredProductsInBackground(readOnlyProducts: [product]) {
                                        onCompletion(.success(product))
                                    }
        }
    }

    /// Synchronizes the products associated with a given Site ID, sorted by ascending name.
    ///
    func synchronizeProducts(siteID: Int64,
                             pageNumber: Int,
                             pageSize: Int,
                             stockStatus: ProductStockStatus?,
                             productStatus: ProductStatus?,
                             productType: ProductType?,
                             sortOrder: ProductsSortOrder,
                             onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.loadAllProducts(for: siteID,
                               pageNumber: pageNumber,
                               pageSize: pageSize,
                               stockStatus: stockStatus,
                               productStatus: productStatus,
                               productType: productType,
                               orderBy: sortOrder.remoteOrderKey,
                               order: sortOrder.remoteOrder) { [weak self] (products, error) in
            guard let products = products else {
                onCompletion(error)
                return
            }

            if pageNumber == Default.firstPageNumber {
                self?.deleteStoredProducts(siteID: siteID)
            }

            self?.upsertStoredProductsInBackground(readOnlyProducts: products) {
                onCompletion(nil)
            }
        }
    }

    /// Synchronizes the Products found in a specified Order.
    ///
    func requestMissingProducts(for order: Order, onCompletion: @escaping (Error?) -> Void) {
        let itemIDs = order.items.map { $0.productID }
        let productIDs = itemIDs.uniqued()  // removes duplicate product IDs

        let storage = storageManager.viewStorage
        var missingIDs = [Int64]()
        for productID in productIDs {
            let storageProduct = storage.loadProduct(siteID: order.siteID, productID: productID)
            if storageProduct == nil {
                missingIDs.append(productID)
            }
        }

        let remote = ProductsRemote(network: network)
        remote.loadProducts(for: order.siteID, by: missingIDs) { [weak self] (products, error) in
            guard let products = products else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductsInBackground(readOnlyProducts: products, onCompletion: {
                onCompletion(nil)
            })
        }
    }

    /// Retrieves multiple products with a given siteID + productIDs.
    /// - Note: This is NOT a wrapper for retrieving a single product.
    ///
    func retrieveProducts(siteID: Int64,
                          productIDs: [Int64],
                          onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.loadProducts(for: siteID, by: productIDs) { [weak self] (products, error) in
            guard let products = products else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductsInBackground(readOnlyProducts: products, onCompletion: {
                onCompletion(nil)
            })
        }
    }

    /// Retrieves the product associated with a given siteID + productID (if any!).
    ///
    func retrieveProduct(siteID: Int64, productID: Int64, onCompletion: @escaping (Networking.Product?, Error?) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.loadProduct(for: siteID, productID: productID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure(let error):
                if case NetworkError.notFound = error {
                    self.deleteStoredProduct(siteID: siteID, productID: productID)
                }
                onCompletion(nil, error)
            case .success(let product):
                self.upsertStoredProductsInBackground(readOnlyProducts: [product]) { [weak self] in
                    let storageProduct = self?.storageManager.viewStorage.loadProduct(siteID: siteID, productID: productID)
                    onCompletion(storageProduct?.toReadOnly(), nil)
                }
            }

        }
    }

    /// Updates the product.
    ///
    func updateProduct(product: Product, onCompletion: @escaping (Result<Product, ProductUpdateError>) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.updateProduct(product: product) { [weak self] (product, error) in
            guard let product = product else {
                onCompletion(.failure(error.map { ProductUpdateError(error: $0) } ?? ProductUpdateError.unknown))
                return
            }

            self?.upsertStoredProductsInBackground(readOnlyProducts: [product]) { [weak self] in
                guard let storageProduct = self?.storageManager.viewStorage.loadProduct(siteID: product.siteID, productID: product.productID) else {
                    onCompletion(.failure(.notFoundInStorage))
                    return
                }
                onCompletion(.success(storageProduct.toReadOnly()))
            }
        }
    }

    /// Validates the Product SKU against other Products in storage.
    ///
    func validateProductSKU(_ sku: String?, siteID: Int64, onCompletion: @escaping (Bool) -> Void) {
        guard let sku = sku, sku.isEmpty == false else {
            // It is valid to not have a sku.
            onCompletion(true)
            return
        }

        let remote = ProductsRemote(network: network)
        remote.searchSku(for: siteID, sku: sku) { (result, error) in
            guard error == nil else {
                onCompletion(true)
                return
            }
            let isValid = (result != nil && result == sku) ? false : true
            onCompletion(isValid)
        }
    }
}


// MARK: - Storage: Product
//
private extension ProductStore {

    /// Deletes any Storage.Product with the specified `siteID` and `productID`
    ///
    func deleteStoredProduct(siteID: Int64, productID: Int64) {
        let storage = storageManager.viewStorage
        guard let product = storage.loadProduct(siteID: siteID, productID: productID) else {
            return
        }

        storage.deleteObject(product)
        storage.saveIfNeeded()
    }

    /// Deletes any Storage.Product with the specified `siteID`
    ///
    func deleteStoredProducts(siteID: Int64) {
        let storage = storageManager.viewStorage
        storage.deleteProducts(siteID: siteID)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly Product Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductsInBackground(readOnlyProducts: [Networking.Product], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertStoredProducts(readOnlyProducts: readOnlyProducts, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Product Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProducts: Remote Products to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredProducts(readOnlyProducts: [Networking.Product], in storage: StorageType) {
        for readOnlyProduct in readOnlyProducts {
            let storageProduct = storage.loadProduct(siteID: readOnlyProduct.siteID, productID: readOnlyProduct.productID) ??
                storage.insertNewObject(ofType: Storage.Product.self)

            storageProduct.update(with: readOnlyProduct)
            handleProductShippingClass(storageProduct: storageProduct, storage)
            handleProductDimensions(readOnlyProduct, storageProduct, storage)
            handleProductAttributes(readOnlyProduct, storageProduct, storage)
            handleProductDefaultAttributes(readOnlyProduct, storageProduct, storage)
            handleProductImages(readOnlyProduct, storageProduct, storage)
            handleProductCategories(readOnlyProduct, storageProduct, storage)
            handleProductTags(readOnlyProduct, storageProduct, storage)
        }
    }

    /// Updates or inserts the provided StorageProduct's dimensions using the provided read-only Product's dimensions
    ///
    func handleProductDimensions(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        if let existingStorageDimensions = storageProduct.dimensions {
            existingStorageDimensions.update(with: readOnlyProduct.dimensions)
        } else {
            let newStorageDimensions = storage.insertNewObject(ofType: Storage.ProductDimensions.self)
            newStorageDimensions.update(with: readOnlyProduct.dimensions)
            storageProduct.dimensions = newStorageDimensions
        }
    }

    /// Updates the provided StorageProduct's productShippingClass using the existing `ProductShippingClass` in storage, if any
    ///
    func handleProductShippingClass(storageProduct: Storage.Product, _ storage: StorageType) {
        if let existingStorageShippingClass = storage.loadProductShippingClass(siteID: storageProduct.siteID,
                                                                               remoteID: storageProduct.shippingClassID) {
            storageProduct.productShippingClass = existingStorageShippingClass
        } else {
            storageProduct.productShippingClass = nil
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's attributes using the provided read-only Product's attributes
    ///
    func handleProductAttributes(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID
        let productID = readOnlyProduct.productID

        // Upsert the attributes from the read-only product
        for readOnlyAttribute in readOnlyProduct.attributes {
            if let existingStorageAttribute = storage.loadProductAttribute(siteID: siteID,
                                                                           productID: productID,
                                                                           attributeID: readOnlyAttribute.attributeID,
                                                                           name: readOnlyAttribute.name) {
                existingStorageAttribute.update(with: readOnlyAttribute)
            } else {
                let newStorageAttribute = storage.insertNewObject(ofType: Storage.ProductAttribute.self)
                newStorageAttribute.update(with: readOnlyAttribute)
                storageProduct.addToAttributes(newStorageAttribute)
            }
        }

        // Now, remove any objects that exist in storageProduct.attributes but not in readOnlyProduct.attributes
        storageProduct.attributes?.forEach { storageAttribute in
            if readOnlyProduct.attributes.first(where: { $0.attributeID == storageAttribute.attributeID && $0.name == storageAttribute.name } ) == nil {
                storageProduct.removeFromAttributes(storageAttribute)
                storage.deleteObject(storageAttribute)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's default attributes using the provided read-only Product's default attributes
    ///
    func handleProductDefaultAttributes(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID
        let productID = readOnlyProduct.productID

        // Upsert the default attributes from the read-only product
        for readOnlyDefaultAttribute in readOnlyProduct.defaultAttributes {
            if let existingStorageDefaultAttribute = storage.loadProductDefaultAttribute(siteID: siteID,
                                                                                         productID: productID,
                                                                                         defaultAttributeID: readOnlyDefaultAttribute.attributeID,
                                                                                         name: readOnlyDefaultAttribute.name ?? "") {
                existingStorageDefaultAttribute.update(with: readOnlyDefaultAttribute)
            } else {
                let newStorageDefaultAttribute = storage.insertNewObject(ofType: Storage.ProductDefaultAttribute.self)
                newStorageDefaultAttribute.update(with: readOnlyDefaultAttribute)
                storageProduct.addToDefaultAttributes(newStorageDefaultAttribute)
            }
        }

        // Now, remove any objects that exist in storageProduct.defaultAttributes but not in readOnlyProduct.defaultAttributes
        storageProduct.defaultAttributes?.forEach { storageDefaultAttribute in
            if readOnlyProduct.defaultAttributes.first(where: {
                $0.attributeID == storageDefaultAttribute.attributeID && $0.name == storageDefaultAttribute.name } ) == nil {
                    storageProduct.removeFromDefaultAttributes(storageDefaultAttribute)
                    storage.deleteObject(storageDefaultAttribute)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's images using the provided read-only Product's images
    ///
    func handleProductImages(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        // Removes all the images first.
        storageProduct.imagesArray.forEach { existingStorageImage in
            storage.deleteObject(existingStorageImage)
        }

        // Inserts the images from the read-only product variation.
        var storageImages = [StorageProductImage]()
        for readOnlyImage in readOnlyProduct.images {
            let newStorageImage = storage.insertNewObject(ofType: Storage.ProductImage.self)
            newStorageImage.update(with: readOnlyImage)
            storageImages.append(newStorageImage)
        }
        storageProduct.images = NSOrderedSet(array: storageImages)
    }

    /// Updates, inserts, or prunes the provided StorageProduct's categories using the provided read-only Product's categories
    ///
    func handleProductCategories(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID

        // Remove previous linked categories
        storageProduct.categories?.removeAll()

        // Upsert the categories from the read-only product
        for readOnlyCategory in readOnlyProduct.categories {
            if let existingStorageCategory = storage.loadProductCategory(siteID: siteID, categoryID: readOnlyCategory.categoryID) {
                // ProductCategory response comes without a `parentID` so we update it with the `existingStorageCategory` one
                let completeReadOnlyCategory = readOnlyCategory.parentIDUpdated(parentID: existingStorageCategory.parentID)
                existingStorageCategory.update(with: completeReadOnlyCategory)
                storageProduct.addToCategories(existingStorageCategory)
            } else {
                let newStorageCategory = storage.insertNewObject(ofType: Storage.ProductCategory.self)
                newStorageCategory.update(with: readOnlyCategory)
                storageProduct.addToCategories(newStorageCategory)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageProduct's tags using the provided read-only Product's tags
    ///
    func handleProductTags(_ readOnlyProduct: Networking.Product, _ storageProduct: Storage.Product, _ storage: StorageType) {
        let siteID = readOnlyProduct.siteID
        let productID = readOnlyProduct.productID

        // Upsert the tags from the read-only product
        for readOnlyTag in readOnlyProduct.tags {
            if let existingStorageTag = storage.loadProductTag(siteID: siteID,
                                                               productID: productID,
                                                               tagID: readOnlyTag.tagID) {
                existingStorageTag.update(with: readOnlyTag)
            } else {
                let newStorageTag = storage.insertNewObject(ofType: Storage.ProductTag.self)
                newStorageTag.update(with: readOnlyTag)
                storageProduct.addToTags(newStorageTag)
            }
        }

        // Now, remove any objects that exist in storageProduct.tags but not in readOnlyProduct.tags
        storageProduct.tags?.forEach { storageTag in
            if readOnlyProduct.tags.first(where: { $0.tagID == storageTag.tagID } ) == nil {
                storageProduct.removeFromTags(storageTag)
                storage.deleteObject(storageTag)
            }
        }
    }
}


// MARK: - Storage: Search Results
//
private extension ProductStore {

    /// Upserts the Products, and associates them to the SearchResults Entity (in Background)
    ///
    private func upsertSearchResultsInBackground(siteID: Int64, keyword: String, readOnlyProducts: [Networking.Product], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProducts(readOnlyProducts: readOnlyProducts, in: derivedStorage)
            self?.upsertStoredResults(siteID: siteID, keyword: keyword, readOnlyProducts: readOnlyProducts, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Upserts the Products, and associates them to the Search Results Entity (in the specified Storage)
    ///
    private func upsertStoredResults(siteID: Int64, keyword: String, readOnlyProducts: [Networking.Product], in storage: StorageType) {
        let searchResults = storage.loadProductSearchResults(keyword: keyword) ?? storage.insertNewObject(ofType: Storage.ProductSearchResults.self)
        searchResults.keyword = keyword

        for readOnlyProduct in readOnlyProducts {
            guard let storedProduct = storage.loadProduct(siteID: siteID, productID: readOnlyProduct.productID) else {
                continue
            }

            searchResults.addToProducts(storedProduct)
        }
    }
}


// MARK: - Unit Testing Helpers
//
extension ProductStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Product in a given Storage Layer.
    ///
    func upsertStoredProduct(readOnlyProduct: Networking.Product, in storage: StorageType) {
        upsertStoredProducts(readOnlyProducts: [readOnlyProduct], in: storage)
    }
}

/// An error that occurs while updating a Product.
///
/// - duplicatedSKU: the SKU is used by another Product.
/// - invalidSKU: the SKU is invalid or duplicated.
/// - unknown: other error cases.
///
public enum ProductUpdateError: Error {
    case duplicatedSKU
    case invalidSKU
    case notFoundInStorage
    case unknown

    init(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            self = .unknown
            return
        }
        switch dotcomError {
        case .unknown(let code, _):
            guard let errorCode = ErrorCode(rawValue: code) else {
                self = .unknown
                return
            }
            self = errorCode.error
        default:
            self = .unknown
        }
    }

    private enum ErrorCode: String {
        case invalidSKU = "product_invalid_sku"

        var error: ProductUpdateError {
            switch self {
            case .invalidSKU:
                return .invalidSKU
            }
        }
    }
}
