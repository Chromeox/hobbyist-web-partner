import SwiftUI

// MARK: - Participant Selection View
struct ParticipantSelectionView: View {
    @Binding var participantCount: Int
    let maxParticipants: Int
    let pricePerPerson: Double
    
    @State private var animatePrice = false
    
    private var totalPrice: Double {
        pricePerPerson * Double(participantCount)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Class Capacity Info
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Available Spots: \(maxParticipants)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // Participant Counter
            VStack(spacing: 16) {
                Text("Number of Participants")
                    .font(.headline)
                
                HStack(spacing: 32) {
                    Button(action: {
                        if participantCount > 1 {
                            withAnimation(.spring()) {
                                participantCount -= 1
                                animatePrice.toggle()
                            }
                            HapticFeedbackService.shared.selectionFeedback.selectionChanged()
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(participantCount > 1 ? .blue : .gray)
                    }
                    .disabled(participantCount <= 1)
                    
                    Text("\(participantCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(width: 80)
                        .scaleEffect(animatePrice ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: participantCount)
                    
                    Button(action: {
                        if participantCount < maxParticipants {
                            withAnimation(.spring()) {
                                participantCount += 1
                                animatePrice.toggle()
                            }
                            HapticFeedbackService.shared.selectionFeedback.selectionChanged()
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(participantCount < maxParticipants ? .blue : .gray)
                    }
                    .disabled(participantCount >= maxParticipants)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            // Price Breakdown
            VStack(spacing: 12) {
                HStack {
                    Text("Price per person")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatPrice(pricePerPerson))
                }
                
                if participantCount > 1 {
                    HStack {
                        Text("\(participantCount) participants")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("× \(participantCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(formatPrice(totalPrice))
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                        .scaleEffect(animatePrice ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3), value: totalPrice)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
}

// MARK: - Booking Details View
struct BookingDetailsView: View {
    @Binding var specialRequests: String
    let selectedClass: HobbyClass
    
    @State private var characterCount = 0
    let maxCharacters = 500
    
    var body: some View {
        VStack(spacing: 24) {
            // Class Summary Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(selectedClass.title)
                            .font(.headline)
                        Text(selectedClass.formattedDateTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.purple)
                    Text(selectedClass.location)
                        .font(.subheadline)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.green)
                    Text(selectedClass.instructor)
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            // Special Requests
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Special Requests (Optional)")
                        .font(.headline)
                    Spacer()
                    Text("\(characterCount)/\(maxCharacters)")
                        .font(.caption)
                        .foregroundColor(characterCount > maxCharacters * 0.8 ? .orange : .secondary)
                }
                
                TextEditor(text: $specialRequests)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: specialRequests) { newValue in
                        characterCount = newValue.count
                        if characterCount > maxCharacters {
                            specialRequests = String(newValue.prefix(maxCharacters))
                            HapticFeedbackService.shared.notificationFeedback.notificationOccurred(.warning)
                        }
                    }
                
                Text("Add any dietary restrictions, accessibility needs, or preferences")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Important Notes
            VStack(alignment: .leading, spacing: 8) {
                Label("Important Information", systemImage: "info.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Arrive 15 minutes early for check-in")
                    Text("• Bring water and comfortable clothing")
                    Text("• Cancellation allowed up to 24 hours before class")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }
}

// MARK: - Payment Selection View
struct PaymentSelectionView: View {
    @Binding var selectedMethod: PaymentMethod
    @Binding var appliedCoupon: Coupon?
    let totalPrice: Double
    let onApplyCoupon: (String) -> Void
    
    @State private var couponCode = ""
    @State private var showingCouponField = false
    @State private var isApplyingCoupon = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Payment Methods
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Payment Method")
                    .font(.headline)
                
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: selectedMethod == method,
                        onTap: {
                            withAnimation(.spring()) {
                                selectedMethod = method
                            }
                            HapticFeedbackService.shared.selectionFeedback.selectionChanged()
                        }
                    )
                }
            }
            
            // Coupon Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Promo Code")
                        .font(.headline)
                    Spacer()
                    if appliedCoupon != nil {
                        Button(action: {
                            appliedCoupon = nil
                            couponCode = ""
                            HapticFeedbackService.shared.impactFeedback.impactOccurred(intensity: 0.5)
                        }) {
                            Text("Remove")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if appliedCoupon != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Code '\(appliedCoupon!.code)' applied")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                        Text("-\(formatPrice(appliedCoupon!.discountAmount(for: totalPrice)))")
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                } else {
                    if showingCouponField {
                        HStack {
                            TextField("Enter code", text: $couponCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                            
                            Button(action: {
                                isApplyingCoupon = true
                                onApplyCoupon(couponCode)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isApplyingCoupon = false
                                }
                            }) {
                                if isApplyingCoupon {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Apply")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .disabled(couponCode.isEmpty || isApplyingCoupon)
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                showingCouponField = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.blue)
                                Text("Add promo code")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Security Badge
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("Your payment information is secure and encrypted")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.05))
            )
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: paymentIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)
                
                Text(method.rawValue)
                    .font(.subheadline.bold())
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    private var paymentIcon: String {
        switch method {
        case .creditCard:
            return "creditcard.fill"
        case .debitCard:
            return "creditcard"
        case .applePay:
            return "apple.logo"
        case .paypal:
            return "p.circle.fill"
        }
    }
}

// MARK: - Booking Review View
struct BookingReviewView: View {
    let hobbyClass: HobbyClass
    let participantCount: Int
    let specialRequests: String
    let paymentMethod: PaymentMethod
    let appliedCoupon: Coupon?
    let totalPrice: Double
    let savings: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Review Your Booking")
                .font(.title2.bold())
                .padding(.bottom)
            
            // Class Details
            ReviewSection(title: "Class Details") {
                ReviewRow(label: "Class", value: hobbyClass.title)
                ReviewRow(label: "Date & Time", value: hobbyClass.formattedDateTime)
                ReviewRow(label: "Location", value: hobbyClass.location)
                ReviewRow(label: "Instructor", value: hobbyClass.instructor)
            }
            
            // Booking Details
            ReviewSection(title: "Booking Details") {
                ReviewRow(label: "Participants", value: "\(participantCount) person(s)")
                if !specialRequests.isEmpty {
                    ReviewRow(label: "Special Requests", value: specialRequests)
                }
            }
            
            // Payment Summary
            ReviewSection(title: "Payment Summary") {
                ReviewRow(label: "Payment Method", value: paymentMethod.rawValue)
                ReviewRow(label: "Subtotal", value: formatPrice(hobbyClass.price * Double(participantCount)))
                if savings > 0 {
                    ReviewRow(label: "Discount", value: "-\(formatPrice(savings))", valueColor: .green)
                }
                Divider()
                ReviewRow(label: "Total", value: formatPrice(totalPrice), isTotal: true)
            }
            
            // Terms & Conditions
            HStack {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.blue)
                Text("I agree to the terms and cancellation policy")
                    .font(.caption)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
            )
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$0.00"
    }
}

// MARK: - Review Section
struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

// MARK: - Review Row
struct ReviewRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundColor(isTotal ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(isTotal ? .title3.bold() : .subheadline)
                .foregroundColor(isTotal ? .blue : valueColor)
        }
    }
}

// MARK: - Booking Confirmation View
struct BookingConfirmationView: View {
    let booking: Booking
    let onDone: () -> Void
    
    @State private var showConfetti = false
    @State private var scaleAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(scaleAnimation ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5).repeatCount(2, autoreverses: true), value: scaleAnimation)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(scaleAnimation ? 1.1 : 1.0)
            }
            .onAppear {
                scaleAnimation = true
                showConfetti = true
                
                // Celebration haptic
                HapticFeedbackService.shared.notificationFeedback.notificationOccurred(.success)
            }
            
            Text("Booking Confirmed!")
                .font(.title.bold())
            
            Text("Your booking has been successfully confirmed. You'll receive a confirmation email shortly.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Booking Details Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "ticket.fill")
                        .foregroundColor(.blue)
                    Text("Booking ID: \(booking.id.prefix(8))...")
                        .font(.caption.monospaced())
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = booking.id
                        HapticFeedbackService.shared.notificationFeedback.notificationOccurred(.success)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    InfoRow(icon: "calendar", label: booking.className)
                    InfoRow(icon: "clock", label: booking.formattedDateTime)
                    InfoRow(icon: "location", label: booking.venue.name)
                    InfoRow(icon: "person.fill", label: "\(booking.participantCount) participant(s)")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    // Add to calendar logic
                }) {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onDone) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .overlay(
            showConfetti ? ConfettiView() : nil
        )
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                ConfettiPiece()
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    @State private var position = CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                         y: -20)
    @State private var opacity: Double = 1
    
    let color = [Color.red, .blue, .green, .yellow, .purple, .orange].randomElement()!
    let size = CGFloat.random(in: 4...8)
    let duration = Double.random(in: 2...4)
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: duration)) {
                    position.y = UIScreen.main.bounds.height + 20
                    opacity = 0
                }
            }
    }
}

// MARK: - HobbyClass Extension
extension HobbyClass {
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}

// MARK: - Booking Extension
extension Booking {
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: classStartDate)
    }
}