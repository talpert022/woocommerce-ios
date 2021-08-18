import SwiftUI

struct InPersonPaymentsStripeAcountReview: View {
    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                Image(uiImage: .paymentErrorImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180.0)
                Text(Localization.message)
                    .font(.callout)
                InPersonPaymentsSupportLink()
            }
            .multilineTextAlignment(.center)

            Spacer()

            InPersonPaymentsLearnMore()
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when the Stripe account is restricted because it's under reviw"
    )

    static let message = NSLocalizedString(
        "You'll be able to accept In-Person Payments as soon as we finish reviewing your account.",
        comment: "Error message when WooCommerce Payments is not supported because the Stripe account is under review"
    )
}

struct InPersonPaymentsStripeAcountReview_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeAcountReview()
    }
}
