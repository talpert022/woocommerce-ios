import Combine
import UIKit
import SwiftUI
import Yosemite

/// View model for `ShippingLabelPackageItem`.
///
final class ShippingLabelPackageItemViewModel: ObservableObject {
    private let order: Order
    private let orderItems: [OrderItem]
    private let currency: String
    private let currencyFormatter: CurrencyFormatter

    /// The packages  response fetched from API
    ///
    let packagesResponse: ShippingLabelPackagesResponse?

    var dimensionUnit: String {
        return packagesResponse?.storeOptions.dimensionUnit ?? ""
    }
    var customPackages: [ShippingLabelCustomPackage] {
        return packagesResponse?.customPackages ?? []
    }
    var predefinedOptions: [ShippingLabelPredefinedOption] {
        return packagesResponse?.predefinedOptions ?? []
    }

    /// Whether there are saved custom or predefined packages to select from.
    ///
    var hasCustomOrPredefinedPackages: Bool {
        return customPackages.isNotEmpty || predefinedOptions.isNotEmpty
    }

    /// The weight unit used in the Store
    ///
    let weightUnit: String?

    /// The items rows observed by the main view `ShippingLabelPackageDetails`
    ///
    @Published private(set) var itemsRows: [ItemToFulfillRow] = []

    /// The id of the selected package. Defaults to last selected package, if any.
    ///
    @Published var selectedPackageID: String

    /// The title of the selected package, if any.
    ///
    var selectedPackageName: String {
        if let selectedCustomPackage = selectedCustomPackage {
            return selectedCustomPackage.title
        }
        else if let selectedPredefinedPackage = selectedPredefinedPackage {
            return selectedPredefinedPackage.title
        }
        else {
            return Localization.selectPackagePlaceholder
        }
    }
    @Published private(set) var selectedCustomPackage: ShippingLabelCustomPackage?
    @Published private(set) var selectedPredefinedPackage: ShippingLabelPredefinedPackage?
    @Published var totalWeight: String = ""

    /// Whether the user has edited the total package weight. If true, we won't make any automatic changes to the total weight.
    ///
    @Published private var isPackageWeightEdited: Bool = false

    /// Returns if the custom packages header should be shown in Package List
    ///
    var showCustomPackagesHeader: Bool {
        return customPackages.count > 0
    }

    init(order: Order,
         orderItems: [OrderItem],
         packagesResponse: ShippingLabelPackagesResponse?,
         selectedPackageID: String,
         totalWeight: String,
         products: [Product],
         productVariations: [ProductVariation],
         formatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings),
         weightUnit: String? = ServiceLocator.shippingSettingsService.weightUnit) {
        self.order = order
        self.orderItems = order.items
        self.currency = order.currency
        self.currencyFormatter = formatter
        self.weightUnit = weightUnit
        self.packagesResponse = packagesResponse
        self.selectedPackageID = selectedPackageID

        didSelectPackage(selectedPackageID)
        confirmPackageSelection()
        configureItemRows(products: products, productVariations: productVariations)
        configureTotalWeights(initialTotalWeight: totalWeight, products: products, productVariations: productVariations)
    }

    private func configureItemRows(products: [Product], productVariations: [ProductVariation]) {
        itemsRows = generateItemsRows(products: products, productVariations: productVariations)
    }

    /// Observe changes in selected custom package, products and variations to update total package weight.
    /// - Parameter initialTotalWeight: the weight value that was input initially.
    /// If this value is different from the calculated weight, we can assume that user has updated the weight manually.
    ///
    private func configureTotalWeights(initialTotalWeight: String, products: [Product], productVariations: [ProductVariation]) {
        if initialTotalWeight.isNotEmpty {
            let calculatedWeight = calculateTotalWeight(products: products, productVariations: productVariations, customPackage: selectedCustomPackage)
            // Return early if manual input is detected
            if initialTotalWeight != String(calculatedWeight) {
                isPackageWeightEdited = true
                return totalWeight = initialTotalWeight
            }
        }

        // Create a stream of changes of calculated weight.
        // This takes into account changes of selected custom package, products and variations.
        // The stream should be completed immediately if manual input of package weight is detected.
        //
        let calculatedWeight = $selectedCustomPackage
            .map { [weak self] customPackage -> Double in
                self?.calculateTotalWeight(products: products, productVariations: productVariations, customPackage: customPackage) ?? 0
            }
            .combineLatest($isPackageWeightEdited)
            .prefix(while: { (_, isEdited) in !isEdited })
            .map { (weight, _) in
                String(weight)
            }

        // Display calculated weight on UI
        //
        calculatedWeight
            .assign(to: &$totalWeight)

        // With every change of total weight, check with latest calculated weight.
        // If the values are different, we can assume that the weight was manually input,
        // and update `isPackageWeightEdited` to true to complete all Combine streams.
        //
        $totalWeight.withLatestFrom(calculatedWeight)
            .map { (totalWeight, calculatedWeight) -> Bool in
                totalWeight != calculatedWeight
            }
            .assign(to: &$isPackageWeightEdited)
    }
}

// MARK: - Helper methods
private extension ShippingLabelPackageItemViewModel {
    /// Generate the items rows, creating an element in the array for every item (eg. if there is an item with quantity 3,
    /// we will generate 3 different items), and we will remove virtual products.
    ///
    func generateItemsRows(products: [Product], productVariations: [ProductVariation]) -> [ItemToFulfillRow] {
        var itemsToFulfill: [ItemToFulfillRow] = []
        for item in orderItems {
            let isVariation = item.variationID > 0
            var product: Product?
            var productVariation: ProductVariation?

            if isVariation {
                productVariation = productVariations.first { $0.productVariationID == item.variationID }
            }
            else {
                product = products.first { $0.productID == item.productID }
            }
            if product?.virtual == false || productVariation?.virtual == false {
                var tempItemQuantity = Double(truncating: item.quantity as NSDecimalNumber)

                for _ in 0..<item.quantity.intValue {
                    let attributes = item.attributes.map { VariationAttributeViewModel(orderItemAttribute: $0) }
                    var weight = Double(productVariation?.weight ?? product?.weight ?? "0") ?? 0
                    if tempItemQuantity < 1 {
                        weight *= tempItemQuantity
                    } else {
                        tempItemQuantity -= 1
                    }
                    let unit: String = weightUnit ?? ""
                    let subtitle = Localization.subtitle(weight: weight.description,
                                                         weightUnit: unit,
                                                         attributes: attributes)
                    itemsToFulfill.append(ItemToFulfillRow(title: item.name, subtitle: subtitle))
                }
            }
        }
        return itemsToFulfill
    }

    /// Calculate total weight based on the weight of the selected package if it's a custom package;
    /// And the products and products variation inside the order items, only if they are not virtual products.
    ///
    /// Note: Only custom package is needed for input because only custom packages have weight to be included in the total weight.
    ///
    func calculateTotalWeight(products: [Product], productVariations: [ProductVariation], customPackage: ShippingLabelCustomPackage?) -> Double {
        var tempTotalWeight: Double = 0

        // Add each order item's weight to the total weight.
        for item in orderItems {
            let isVariation = item.variationID > 0
            var product: Product?
            var productVariation: ProductVariation?

            if isVariation {
                productVariation = productVariations.first { $0.productVariationID == item.variationID }
            }
            else {
                product = products.first { $0.productID == item.productID }
            }
            if product?.virtual == false || productVariation?.virtual == false {
                let itemWeight = Double(productVariation?.weight ?? product?.weight ?? "0") ?? 0
                tempTotalWeight += itemWeight * Double(truncating: item.quantity as NSDecimalNumber)
            }
        }

        // Add selected package weight to the total weight.
        // Only custom packages have a defined weight, so we only do this if a custom package is selected.
        if let selectedPackage = customPackage {
            tempTotalWeight += selectedPackage.boxWeight
        }
        return tempTotalWeight
    }
}

// MARK: - Package Selection
extension ShippingLabelPackageItemViewModel {
    func didSelectPackage(_ id: String) {
        selectCustomPackage(id)
        selectPredefinedPackage(id)
    }

    private func selectCustomPackage(_ id: String) {
        guard let packagesResponse = packagesResponse else {
            return
        }

        for customPackage in packagesResponse.customPackages {
            if customPackage.title == id {
                selectedCustomPackage = customPackage
                selectedPredefinedPackage = nil
                return
            }
        }
    }

    private func selectPredefinedPackage(_ id: String) {
        guard let packagesResponse = packagesResponse else {
            return
        }

        for option in packagesResponse.predefinedOptions {
            for predefinedPackage in option.predefinedPackages {
                if predefinedPackage.id == id {
                    selectedCustomPackage = nil
                    selectedPredefinedPackage = predefinedPackage
                    return
                }
            }
        }
    }

    /// Writes into the binding variable the final package selection value when confirmed.
    /// Also sets the total weight for the package, including the selected package weight (if any).
    ///
    func confirmPackageSelection() {
        if let selectedCustomPackage = selectedCustomPackage {
            selectedPackageID = selectedCustomPackage.title
        }
        else if let selectedPredefinedPackage = selectedPredefinedPackage {
            selectedPackageID = selectedPredefinedPackage.id
        }
    }
}

private extension ShippingLabelPackageItemViewModel {
    enum Localization {
        static let subtitleFormat =
            NSLocalizedString("%1$@", comment: "In Shipping Labels Package Details,"
                                + " the pattern used to show the weight of a product. For example, “1lbs”.")
        static let subtitleWithAttributesFormat =
            NSLocalizedString("%1$@・%2$@", comment: "In Shipping Labels Package Details if the product has attributes,"
                                + " the pattern used to show the attributes and weight. For example, “purple, has logo・1lbs”."
                                + " The %1$@ is the list of attributes (e.g. from variation)."
                                + " The %2$@ is the weight with the unit.")
        static func subtitle(weight: String?, weightUnit: String, attributes: [VariationAttributeViewModel]) -> String {
            let attributesText = attributes.map { $0.nameOrValue }.joined(separator: ", ")
            let formatter = WeightFormatter(weightUnit: weightUnit)
            let weight = formatter.formatWeight(weight: weight)
            if attributes.isEmpty {
                return String.localizedStringWithFormat(subtitleFormat, weight, weightUnit)
            } else {
                return String.localizedStringWithFormat(subtitleWithAttributesFormat, attributesText, weight)
            }
        }
        static let selectPackagePlaceholder = NSLocalizedString("Select a package",
                                                                comment: "Placeholder for the selected package in the Shipping Labels Package Details screen")
    }
}
