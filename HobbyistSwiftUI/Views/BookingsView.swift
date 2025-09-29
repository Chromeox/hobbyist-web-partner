import SwiftUI

struct BookingsView: View {
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $selectedSegment) {
                    Text(localized: "upcoming").tag(0)
                    Text(localized: "past").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedSegment == 0 {
                    // Upcoming bookings
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<2) { _ in
                                BookingCard(isPast: false)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Past bookings
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<5) { _ in
                                BookingCard(isPast: true)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("My Bookings")
        }
    }
}

struct BookingCard: View {
    let isPast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pottery Making Workshop")
                        .font(.headline)

                    Text(isPast ? "completed on Dec 15, 2024" : "tomorrow at 2:00 PM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPast {
                    Button(NSLocalizedString("rate", comment: "")) {
                        // Rate action
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                } else {
                    Text(localized: "confirmed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            HStack {
                Label(localized: "central_studio", systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !isPast {
                    NavigationLink(destination: ClassDetailView(classItem: ClassItem.sample)) {
                        Text(localized: "view_details")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BookingsView_Previews: PreviewProvider {
    static var previews: some View {
        BookingsView()
    }
}
