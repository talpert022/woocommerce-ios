import Combine
import UIKit
import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType


/// View model for `ShippingLabelPackagesForm`.
///
final class ShippingLabelPackagesFormViewModel: ObservableObject {

    private let order: Order
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private var resultsControllers: ShippingLabelPackageDetailsResultsControllers?

    /// List of selected package with basic info.
    ///
    @Published private var selectedPackages: [ShippingLabelPackageAttributes] = []
    
    /// Products contained inside the Order and fetched from Core Data
    ///
    @Published private var products: [Product] = []

    /// ProductVariations contained inside the Order and fetched from Core Data
    ///
    @Published private var productVariations: [ProductVariation] = []

    init(order: Order,
         packagesResponse: ShippingLabelPackagesResponse?,
         selectedPackages: [ShippingLabelPackageAttributes],
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.order = order
        self.stores = stores
        self.storageManager = storageManager
        self.selectedPackages = selectedPackages

        configureResultsControllers()
        syncProducts()
        syncProductVariations()
        configureDefaultPackage()
    }

    /// If no initial packages was input, set up default package from last selected package ID and all order items.
    ///
    private func configureDefaultPackage() {
        guard selectedPackages.isEmpty,
              let selectedPackageID = resultsControllers?.accountSettings?.lastSelectedPackageID else {
            return
        }
        selectedPackages = [ShippingLabelPackageAttributes(packageID: selectedPackageID,
                                                           totalWeight: "",
                                                           productIDs: order.items.map { $0.productOrVariationID })]
    }

    private func configureResultsControllers() {
        resultsControllers = ShippingLabelPackageDetailsResultsControllers(siteID: order.siteID,
                                                                           orderItems: order.items,
                                                                           storageManager: storageManager,
           onProductReload: { [weak self] (products) in
            guard let self = self else { return }
            self.products = products
        }, onProductVariationsReload: { [weak self] (productVariations) in
            guard let self = self else { return }
            self.productVariations = productVariations
        })

        products = resultsControllers?.products ?? []
        productVariations = resultsControllers?.productVariations ?? []
    }
}

/// API Requests
///
private extension ShippingLabelPackagesFormViewModel {
    func syncProducts(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductAction.requestMissingProducts(for: order) { (error) in
            if let error = error {
                DDLogError("⛔️ Error synchronizing Products: \(error)")
                onCompletion?(error)
                return
            }

            onCompletion?(nil)
        }

        stores.dispatch(action)
    }

    func syncProductVariations(onCompletion: ((Error?) -> ())? = nil) {
        let action = ProductVariationAction.requestMissingVariations(for: order) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing missing variations in an Order: \(error)")
                onCompletion?(error)
                return
            }
            onCompletion?(nil)
        }
        stores.dispatch(action)
    }
}