import SwiftUI

struct ShippingLabelPackageItem: View {
    @ObservedObject private var viewModel: ShippingLabelPackageItemViewModel
    @State private var isCollapsed: Bool = false
    @State private var isShowingNewPackageCreation = false
    
    private let isCollapsible: Bool
    private let packageNumber: Int
    private let safeAreaInsets: EdgeInsets
    
    init(packageNumber: Int,
         isCollapsible: Bool,
         safeAreaInsets: EdgeInsets,
         viewModel: ShippingLabelPackageItemViewModel) {
        self.packageNumber = packageNumber
        self.isCollapsible = isCollapsible
        self.safeAreaInsets = safeAreaInsets
        self.viewModel = viewModel
        self.isCollapsed = packageNumber > 1
    }
    
    var body: some View {
        Text("Hello, World!")
    }
}

private extension ShippingLabelPackageItem {
    enum Localization {
        static let itemsToFulfillHeader = NSLocalizedString("ITEMS TO FULFILL", comment: "Header section items to fulfill in Shipping Label Package Detail")
        static let packageDetailsHeader = NSLocalizedString("PACKAGE DETAILS", comment: "Header section package details in Shipping Label Package Detail")
        static let packageSelected = NSLocalizedString("Package Selected",
                                                       comment: "Title of the row for selecting a package in Shipping Label Package Detail screen")
        static let totalPackageWeight = NSLocalizedString("Total package weight",
                                                          comment: "Title of the row for adding the package weight in Shipping Label Package Detail screen")
        static let footer = NSLocalizedString("Sum of products and package weight",
                                              comment: "Title of the footer in Shipping Label Package Detail screen")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }
}

struct ShippingLabelPackageItem_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelPackageItemViewModel()
        ShippingLabelPackageItem(packageNumber: 1, isCollapsible: true, safeAreaInsets: .zero, viewModel: viewModel)
    }
}
