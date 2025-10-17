import SwiftUI
import Stripe

struct CreditPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var creditService = CreditService.shared

    @State private var paymentSheet: PaymentSheet?
    @State private var currentPaymentIntentId: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && creditService.availableCreditPacks.isEmpty {
                    ProgressView("Loading credit packs…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if let error = creditService.packsError, creditService.availableCreditPacks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.body)
                            .multilineTextAlignment(.center)
                        Button(action: reloadPacks) {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        Section(header: Text("Available Packs")) {
                            ForEach(creditService.availableCreditPacks) { pack in
                                CreditPackRow(pack: pack) {
                                    startPurchase(for: pack)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .overlay(alignment: .center) {
                        if isLoading {
                            ProgressView()
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(radius: 6)
                                )
                        }
                    }
                }
            }
            .navigationTitle("Purchase Credits")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if creditService.availableCreditPacks.isEmpty {
                    Task { await creditService.loadCreditPacks(force: true) }
                }
            }
            .alert(errorMessage ?? "", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { showingErrorAlert = false }
            }
        }
    }

    private func reloadPacks() {
        isLoading = true
        Task {
            await creditService.loadCreditPacks(force: true)
            await MainActor.run { isLoading = false }
        }
    }

    private func startPurchase(for pack: CreditPack) {
        isLoading = true
        Task {
            do {
                let setup = try await creditService.preparePaymentSheet(for: pack)
                if let publishableKey = setup.publishableKey, !publishableKey.isEmpty {
                    StripeAPI.defaultPublishableKey = publishableKey
                }
                await MainActor.run {
                    var configuration = PaymentSheet.Configuration()
                    configuration.merchantDisplayName = "Hobbyist"
                    configuration.applePay = .init(merchantId: Configuration.shared.appleMerchantId, merchantCountryCode: "CA")
                    configuration.customer = .init(id: setup.customerId, ephemeralKeySecret: setup.ephemeralKeySecret)
                    configuration.allowsDelayedPaymentMethods = false

                    paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: setup.paymentIntentClientSecret,
                        configuration: configuration
                    )
                    currentPaymentIntentId = setup.paymentIntentId
                    isLoading = false
                    presentPaymentSheet()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }

    private func presentPaymentSheet() {
        guard let paymentSheet, let paymentIntentId = currentPaymentIntentId,
              let topController = UIApplication.topViewController() else {
            return
        }

        paymentSheet.present(from: topController) { result in
            handlePaymentResult(result, paymentIntentId: paymentIntentId)
        }
    }

    private func handlePaymentResult(_ result: PaymentSheetResult, paymentIntentId: String) {
        switch result {
        case .completed:
            Task {
                do {
                    _ = try await creditService.finalizePurchase(paymentIntentId: paymentIntentId)
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                        showingErrorAlert = true
                    }
                }
            }
        case .canceled:
            break
        case .failed(let error):
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }

        paymentSheet = nil
        currentPaymentIntentId = nil
        isLoading = false
    }
}

private struct CreditPackRow: View {
    let pack: CreditPack
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(pack.name)
                    .font(.headline)
                Spacer()
                Text(pack.formattedPrice)
                    .font(.headline)
            }

            HStack {
                Label("\(pack.totalCredits) credits", systemImage: "sparkles")
                    .font(.subheadline)
                Spacer()
                if let savings = pack.savingsText {
                    Text(savings)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            Button(action: action) {
                HStack {
                    Spacer()
                    Label("Checkout", systemImage: "creditcard")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }
}
