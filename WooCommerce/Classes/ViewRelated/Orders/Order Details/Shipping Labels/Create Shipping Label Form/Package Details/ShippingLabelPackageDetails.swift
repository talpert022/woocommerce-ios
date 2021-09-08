import SwiftUI
import Yosemite

struct ShippingLabelPackageDetails: View {
    @ObservedObject private var viewModel: ShippingLabelPackageDetailsViewModel
    @Environment(\.presentationMode) var presentation

    /// Completion callback
    ///
    typealias Completion = (_ selectedPackages: [ShippingLabelPackageInfo]) -> Void
    private let onCompletion: Completion

    init(viewModel: ShippingLabelPackageDetailsViewModel, completion: @escaping Completion) {
        self.viewModel = viewModel
        onCompletion = completion
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "packages_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ForEach(Array(viewModel.selectedPackages.enumerated()), id: \.element) { index, element in
                    viewModel.itemViewModels.first(where: { $0.selectedPackageID == element.packageID }).map { itemViewModel in
                        ShippingLabelPackageItem(packageNumber: index + 1,
                                                 isCollapsible: viewModel.selectedPackages.count > 1,
                                                 safeAreaInsets: geometry.safeAreaInsets,
                                                 viewModel: itemViewModel)
                    }
                }
                .padding(.bottom, insets: geometry.safeAreaInsets)
            }
            .background(Color(.listBackground))
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        }
        .navigationTitle(Localization.title)
        .navigationBarItems(trailing: Button(action: {
            ServiceLocator.analytics.track(.shippingLabelPurchaseFlow,
                                           withProperties: ["state": "packages_selected"])
            // TODO: update selection
//            onCompletion(viewModel.selectedPackagesDetails)
            presentation.wrappedValue.dismiss()
        }, label: {
            Text(Localization.doneButton)
        })
        .disabled(!viewModel.doneButtonEnabled))
    }
}

private extension ShippingLabelPackageDetails {
    enum Localization {
        static let title = NSLocalizedString("Package Details",
                                             comment: "Navigation bar title of shipping label package details screen")
        static let itemsToFulfillHeader = NSLocalizedString("ITEMS TO FULFILL", comment: "Header section items to fulfill in Shipping Label Package Detail")
        static let packageDetailsHeader = NSLocalizedString("PACKAGE DETAILS", comment: "Header section package details in Shipping Label Package Detail")
        static let packageSelected = NSLocalizedString("Package Selected",
                                                       comment: "Title of the row for selecting a package in Shipping Label Package Detail screen")
        static let totalPackageWeight = NSLocalizedString("Total package weight",
                                                          comment: "Title of the row for adding the package weight in Shipping Label Package Detail screen")
        static let footer = NSLocalizedString("Sum of products and package weight",
                                              comment: "Title of the footer in Shipping Label Package Detail screen")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Package Details screen in Shipping Label flow")
    }

    enum Constants {
        static let dividerPadding: CGFloat = 16
    }
}

struct ShippingLabelPackageDetails_Previews: PreviewProvider {

    static var previews: some View {

        let viewModel = ShippingLabelPackageDetailsViewModel(order: ShippingLabelPackageDetailsViewModel.sampleOrder(),
                                                             packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails(),
                                                             selectedPackages: [])

        ShippingLabelPackageDetails(viewModel: viewModel, completion: { _ in
        })
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        ShippingLabelPackageDetails(viewModel: viewModel, completion: { _ in
        })
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")
    }
}
