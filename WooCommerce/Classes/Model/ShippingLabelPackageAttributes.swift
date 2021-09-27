import Foundation

/// A structure to hold the basic details for a selected package on Package Details screen of Shipping Label purchase flow.
///
struct ShippingLabelPackageAttributes: Equatable {

    /// ID of the selected package.
    let packageID: String

    /// Total weight of the package in string value.
    let totalWeight: String

    /// List of items in the package.
    let items: [ShippingLabelPackageItem]
}
