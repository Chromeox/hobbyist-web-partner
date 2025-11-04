import SwiftUI

struct ClassPreferencesView: View {
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
                Section("Preferred Categories") {
                    ForEach(ClassCategory.allCases, id: \.self) { category in
                        HStack {
                            Label(category.displayName, systemImage: category.iconName)
                            Spacer()
                            if tempPreferences.preferredCategories.contains(category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleCategory(category)
                        }
                    }
                }
                
                Section("Difficulty Level") {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        HStack {
                            Text(level.displayName)
                            Spacer()
                            if tempPreferences.preferredDifficulty == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempPreferences.preferredDifficulty = level
                        }
                    }
                }
                
                Section("Maximum Price") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("$0")
                            Spacer()
                            Text("$\(Int(tempPreferences.maxPrice))")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("$500")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Slider(
                            value: $tempPreferences.maxPrice,
                            in: 0...500,
                            step: 25
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Preferred Days") {
                    ForEach(UserPreferences.WeekDay.allCases, id: \.self) { day in
                        HStack {
                            Text(day.displayName)
                            Spacer()
                            if tempPreferences.preferredDays.contains(day) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
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
                            VStack(alignment: .leading) {
                                Text(timeSlot.displayName)
                            }
                            Spacer()
                            if tempPreferences.preferredTimeSlots.contains(timeSlot) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTimeSlot(timeSlot)
                        }
                    }
                }
            }
            .navigationTitle("Class Preferences")
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
    
    private func toggleCategory(_ category: ClassCategory) {
        if tempPreferences.preferredCategories.contains(category) {
            tempPreferences.preferredCategories.removeAll { $0 == category }
        } else {
            tempPreferences.preferredCategories.append(category)
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
}

// MARK: - Extensions for Display

extension ClassCategory {
    var iconName: String {
        switch self {
        case .fitness: return "figure.run"
        case .yoga: return "figure.yoga"
        case .dance: return "figure.dance"
        case .martial_arts: return "figure.martial.arts"
        case .cooking: return "fork.knife"
        case .art: return "paintbrush"
        case .music: return "music.note"
        case .pottery: return "hands.clap"
        case .photography: return "camera"
        case .language: return "text.bubble"
        case .tech: return "laptopcomputer"
        case .crafts: return "scissors"
        case .wellness: return "heart"
        case .sports: return "soccerball"
        case .outdoor: return "tree"
        }
    }
}

extension DifficultyLevel {
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .all_levels: return "All Levels"
        }
    }
}

struct ClassPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        ClassPreferencesView(preferences: .constant(UserPreferences()))
    }
}