import SwiftUI
import EventKit

struct BookingConfirmationView: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    @EnvironmentObject var hapticService: HapticFeedbackService
    @Environment(\.dismiss) var dismiss
    
    @State private var showConfetti = false
    @State private var showingShareSheet = false
    @State private var confettiOffset: CGFloat = -200
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(showConfetti ? 1.2 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .scaleEffect(showConfetti ? 1.0 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showConfetti)
                    
                    // Confetti animation
                    if showConfetti {
                        ForEach(0..<20, id: \.self) { _ in
                            ConfettiPiece()
                        }
                    }
                }
                .padding(.top, 40)
                
                // Success Message
                VStack(spacing: 12) {
                    Text("Booking Confirmed!")
                        .font(BrandConstants.Typography.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Your spot is reserved")
                        .font(BrandConstants.Typography.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Confirmation Code
                VStack(spacing: 12) {
                    Text("Confirmation Code")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(viewModel.confirmationCode)
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Button {
                            copyConfirmationCode()
                        } label: {
                            Image(systemName: "doc.on.doc.fill")
                                .font(BrandConstants.Typography.title3)
                                .foregroundColor(.accentColor)
                                .padding()
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                
                // Class Summary
                ClassSummarySection(viewModel: viewModel)
                
                // What's Next
                WhatsNextSection(viewModel: viewModel)
                
                // Quick Actions
                QuickActionsSection(
                    viewModel: viewModel,
                    onAddToCalendar: addToCalendar,
                    onShare: { showingShareSheet = true },
                    onGetDirections: getDirections
                )
                
                // Done Button
                Button {
                    hapticService.playSuccess()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(BrandConstants.Typography.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding()
        }
        .onAppear {
            triggerSuccessAnimation()
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
    }
    
    // MARK: - Private Methods
    
    private func triggerSuccessAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            showConfetti = true
        }
        
        // Add haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            hapticService.playBookingSuccess()
        }
    }
    
    private func copyConfirmationCode() {
        UIPasteboard.general.string = viewModel.confirmationCode
        hapticService.playLight()
        
        // Show toast or temporary feedback
        // This could be enhanced with a toast notification
    }
    
    private func addToCalendar() {
        guard let classItem = viewModel.selectedClass,
              let timeSlot = viewModel.selectedTimeSlot else { return }
        
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if granted && error == nil {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = classItem.name
                    event.startDate = timeSlot.date
                    event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: timeSlot.date) ?? timeSlot.date
                    event.location = classItem.venueName
                    event.notes = """
                    Booking Confirmation: \(viewModel.confirmationCode)
                    Instructor: \(classItem.instructor)
                    Participants: \(viewModel.participantCount)
                    
                    Special Requests: \(viewModel.specialRequests.isEmpty ? "None" : viewModel.specialRequests)
                    """
                    event.calendar = eventStore.defaultCalendarForNewEvents
                    
                    // Add 24-hour reminder
                    let reminder = EKAlarm(relativeOffset: -24 * 60 * 60) // 24 hours before
                    event.addAlarm(reminder)
                    
                    // Add 1-hour reminder
                    let lastMinuteReminder = EKAlarm(relativeOffset: -60 * 60) // 1 hour before
                    event.addAlarm(lastMinuteReminder)
                    
                    do {
                        try eventStore.save(event, span: .thisEvent)
                        hapticService.playSuccess()
                        // Show success feedback
                    } catch {
                        print("Failed to save event: \(error)")
                        // Show error feedback
                    }
                } else {
                    // Handle permission denied
                    print("Calendar access denied")
                }
            }
        }
    }
    
    private func getDirections() {
        guard let classItem = viewModel.selectedClass else { return }
        
        let venue = classItem.venueName
        let query = venue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
    
    private var shareItems: [Any] {
        guard let classItem = viewModel.selectedClass,
              let timeSlot = viewModel.selectedTimeSlot else { return [] }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        let shareText = """
        I just booked a \(classItem.name) class!
        
        📅 \(dateFormatter.string(from: timeSlot.date))
        📍 \(classItem.venueName)
        👩‍🏫 With \(classItem.instructor)
        
        Confirmation: \(viewModel.confirmationCode)
        
        Booked through HobbyApp
        """
        
        return [shareText]
    }
}

// MARK: - Supporting Views

struct ClassSummarySection: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Class Details")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            if let classItem = viewModel.selectedClass,
               let timeSlot = viewModel.selectedTimeSlot {
                
                VStack(spacing: 16) {
                    // Class Info Card
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: classItem.icon)
                                    .font(BrandConstants.Typography.title2)
                                    .foregroundColor(.accentColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(classItem.name)
                                .font(BrandConstants.Typography.headline)
                                .fontWeight(.medium)
                            
                            Text(classItem.venueName)
                                .font(BrandConstants.Typography.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(viewModel.participantCount) participant\(viewModel.participantCount > 1 ? "s" : "")")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Date and Time
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date & Time")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Time")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text(timeSlot.displayTime)
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Instructor
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Instructor")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text(classItem.instructor)
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Duration")
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Text(classItem.duration)
                                .font(BrandConstants.Typography.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct WhatsNextSection: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Next?")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                NextStepItem(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "Confirmation Email",
                    description: "Check your inbox for detailed booking information and class preparation tips"
                )
                
                NextStepItem(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Reminders Set",
                    description: "We'll send you reminders 24 hours and 1 hour before your class"
                )
                
                NextStepItem(
                    icon: "person.2.fill",
                    iconColor: .green,
                    title: "Meet Your Instructor",
                    description: "Your instructor will reach out with any last-minute details or preparation notes"
                )
                
                if !viewModel.specialRequests.isEmpty {
                    NextStepItem(
                        icon: "note.text",
                        iconColor: .purple,
                        title: "Special Requests Noted",
                        description: "We've shared your special requests with the instructor"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct NextStepItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(BrandConstants.Typography.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct QuickActionsSection: View {
    @ObservedObject var viewModel: EnhancedBookingViewModel
    let onAddToCalendar: () -> Void
    let onShare: () -> Void
    let onGetDirections: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add to Calendar",
                    subtitle: "Never miss your class",
                    action: onAddToCalendar
                )
                
                ActionButton(
                    icon: "square.and.arrow.up",
                    title: "Share Booking",
                    subtitle: "Let friends know where you'll be",
                    action: onShare
                )
                
                ActionButton(
                    icon: "map.fill",
                    title: "Get Directions",
                    subtitle: "Navigate to the venue",
                    action: onGetDirections
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(BrandConstants.Typography.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Confetti Animation

struct ConfettiPiece: View {
    @State private var isAnimating = false
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    private let shapes: [String] = ["circle.fill", "star.fill", "heart.fill", "diamond.fill"]
    
    var body: some View {
        Image(systemName: shapes.randomElement() ?? "circle.fill")
            .foregroundColor(colors.randomElement() ?? .blue)
            .font(.caption)
            .offset(
                x: isAnimating ? CGFloat.random(in: -150...150) : 0,
                y: isAnimating ? CGFloat.random(in: 200...400) : -50
            )
            .rotationEffect(.degrees(isAnimating ? Double.random(in: 0...360) : 0))
            .opacity(isAnimating ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 1...2))) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview {
    let viewModel = EnhancedBookingViewModel()
    viewModel.confirmationCode = "AB1234"
    viewModel.bookingComplete = true
    
    return BookingConfirmationView(viewModel: viewModel)
        .environmentObject(HapticFeedbackService.shared)
}