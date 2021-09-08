import SwiftUI

struct ShippingLabelPackageSelection: View {
    @ObservedObject var viewModel: ShippingLabelPackageItemViewModel

    var body: some View {
        NavigationView {
            if viewModel.hasCustomOrPredefinedPackages {
                ShippingLabelPackageList(viewModel: viewModel)
            } else {
                ShippingLabelAddNewPackage(packagesResponse: viewModel.packagesResponse)
            }
        }
    }
}

struct ShippingLabelPackageSelection_Previews: PreviewProvider {
    static var previews: some View {
        let order = ShippingLabelPackageDetailsViewModel.sampleOrder()
        let viewModelWithPackages = ShippingLabelPackageItemViewModel(order: order,
                                                                      orderItems: order.items,
                                                                      packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails(),
                                                                      selectedPackageID: "Box 1",
                                                                      totalWeight: "",
                                                                      products: [],
                                                                      productVariations: []) { _, _ in }
        let viewModelWithoutPackages = ShippingLabelPackageItemViewModel(order: order,
                                                                         orderItems: order.items,
                                                                         packagesResponse: nil,
                                                                         selectedPackageID: "Box 1",
                                                                         totalWeight: "",
                                                                         products: [],
                                                                         productVariations: []) { _, _ in }

        ShippingLabelPackageSelection(viewModel: viewModelWithPackages)

        ShippingLabelPackageSelection(viewModel: viewModelWithoutPackages)
    }
}
