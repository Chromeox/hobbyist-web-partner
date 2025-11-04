import SwiftUI

struct TimePreferencesView: View {
    @Binding var preferences: UserPreferences
    @State private var tempPreferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    
    init(preferences: Binding<UserPreferences>) {
        self._preferences = preferences
        self._tempPreferences = State(initialValue: preferences.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Preferred Days") {
                    ForEach(UserPreferences.WeekDay.allCases, id: \.self) { day in
                        HStack {
                            Text(day.displayName)
                            Spacer()
                            if tempPreferences.preferredDays.contains(day) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleDay(day)
                        }
                    }
                }
                
                Section("Preferred Time Slots") {
                    ForEach(UserPreferences.TimeSlot.allCases, id: \.self) { timeSlot in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(timeSlotTitle(timeSlot))
                                    .font(.body)
                                Text(timeSlotSubtitle(timeSlot))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if tempPreferences.preferredTimeSlots.contains(timeSlot) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTimeSlot(timeSlot)
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Section("Search Radius") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Notification Radius")
                            Spacer()
                            Text("\(Int(tempPreferences.notificationRadius)) miles")
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("1 mile")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("50 miles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $tempPreferences.notificationRadius,
                            in: 1...50,
                            step: 1
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Text("Select your preferred days and time slots to receive personalized class recommendations. We'll notify you about classes that match your schedule within your selected radius.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Time Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        preferences = tempPreferences
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleDay(_ day: UserPreferences.WeekDay) {
        if tempPreferences.preferredDays.contains(day) {
            tempPreferences.preferredDays.removeAll { $0 == day }
        } else {
            tempPreferences.preferredDays.append(day)
        }
    }
    
    private func toggleTimeSlot(_ timeSlot: UserPreferences.TimeSlot) {
        if tempPreferences.preferredTimeSlots.contains(timeSlot) {
            tempPreferences.preferredTimeSlots.removeAll { $0 == timeSlot }
        } else {
            tempPreferences.preferredTimeSlots.append(timeSlot)
        }
    }
    
    private func timeSlotTitle(_ timeSlot: UserPreferences.TimeSlot) -> String {
        switch timeSlot {
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .lateAfternoon: return "Late Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
    
    private func timeSlotSubtitle(_ timeSlot: UserPreferences.TimeSlot) -> String {
        switch timeSlot {
        case .earlyMorning: return "6:00 AM - 9:00 AM"
        case .morning: return "9:00 AM - 12:00 PM"
        case .afternoon: return "12:00 PM - 3:00 PM"
        case .lateAfternoon: return "3:00 PM - 6:00 PM"
        case .evening: return "6:00 PM - 9:00 PM"
        case .night: return "9:00 PM - 12:00 AM"
        }
    }
}

struct TimePreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        TimePreferencesView(preferences: .constant(UserPreferences()))
    }
}