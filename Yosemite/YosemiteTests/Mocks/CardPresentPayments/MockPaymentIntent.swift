@testable import Hardware

struct MockPaymentIntent {
    static func mock() -> PaymentIntent {
        PaymentIntent(id: "intent_id",
                      status: .requiresCapture,
                      created: Date(),
                      amount: 100,
                      currency: "usd",
                      metadata: nil,
                      charges: mockCharges())
    }
}

private extension MockPaymentIntent {
    static func mockCharges() -> [Charge] {
        [mockCharge()]
    }

    static func mockCharge() -> Charge {
        Charge(id: "charge_id",
               amount: 100,
               currency: "usd",
               status: .succeeded,
               description: "charge_description",
               metadata: nil,
               paymentMethod: mockPaymentMethod())
    }

    static func mockPaymentMethod() -> PaymentMethod {
        .presentCard(details: mockCardDetails())
    }

    static func mockCardDetails() -> CardPresentTransactionDetails {
        CardPresentTransactionDetails(last4: "last4",
                           expMonth: 1,
                           expYear: 2021,
                           cardholderName: "Cardholder",
                           brand: .visa,
                           fingerprint: "fingerprint",
                           generatedCard: "generated_card",
                           receipt: mockReceiptDetails(),
                           emvAuthData: "emv_auth_data")
    }

    static func mockReceiptDetails() -> ReceiptDetails {
        ReceiptDetails(applicationPreferredName: "app_preferred_name",
                       dedicatedFileName: "dedicated_file_name",
                       authorizationResponseCode: "auth_response_code",
                       applicationCryptogram: "app_cryptogram",
                       terminalVerificationResults: "verification_result",
                       transactionStatusInformation: "transaction_status_info",
                       accountType: "account_type")
    }
}