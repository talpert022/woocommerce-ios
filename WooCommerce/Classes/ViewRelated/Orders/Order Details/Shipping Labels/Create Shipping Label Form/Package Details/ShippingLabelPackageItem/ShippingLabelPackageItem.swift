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

private extension ShippingLabelPackageItem {}

struct ShippingLabelPackageItem_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelPackageItemViewModel()
        ShippingLabelPackageItem(packageNumber: 1, isCollapsible: true, safeAreaInsets: .zero, viewModel: viewModel)
    }
}
