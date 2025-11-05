import SwiftUI

// MARK: - Enhanced Search Bar

struct EnhancedSearchBar: View {
    @Binding var text: String
    let suggestions: [String]
    let isListening: Bool
    let voiceText: String
    let onSubmit: () -> Void
    let onClear: () -> Void
    let onVoiceSearch: () -> Void
    let onSuggestionTap: (String) -> Void
    
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: BrandConstants.Spacing.sm) {
                // Search Icon
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isEditing ? BrandConstants.Colors.primary : Color.secondary)
                    .font(.system(size: 18, weight: .medium))
                
                // Text Field
                TextField("Search classes, instructors, venues", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($isTextFieldFocused)
                    .onSubmit(onSubmit)
                    .onChange(of: text) { _, newValue in
                        if newValue.isEmpty {
                            onClear()
                        }
                    }
                    .overlay(
                        // Voice search overlay when listening
                        Group {
                            if isListening {
                                HStack {
                                    Spacer()
                                    Text(voiceText.isEmpty ? "Listening..." : voiceText)
                                        .foregroundColor(BrandConstants.Colors.primary)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                                        .fill(BrandConstants.Colors.primary.opacity(0.1))
                                )
                            }
                        }
                    )
                
                // Action Buttons
                HStack(spacing: BrandConstants.Spacing.xs) {
                    // Clear Button
                    if !text.isEmpty && !isListening {
                        Button(action: onClear) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.secondary)
                                .font(.system(size: 16))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Voice Search Button
                    Button(action: onVoiceSearch) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .foregroundStyle(isListening ? Color.red : BrandConstants.Colors.primary)
                            .font(.system(size: 16, weight: .medium))
                            .scaleEffect(isListening ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isListening)
                    }
                }
            }
            .padding(BrandConstants.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                    .fill(Color(.secondarySystemBackground))
                    .stroke(isEditing ? BrandConstants.Colors.primary : Color.clear, lineWidth: 2)
            )
            .onTapGesture {
                isTextFieldFocused = true
            }
            
            // Autocomplete Suggestions
            if isEditing && !suggestions.isEmpty {
                SuggestionsDropdown(
                    suggestions: suggestions,
                    onSuggestionTap: onSuggestionTap
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            isEditing = isTextFieldFocused
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = focused
            }
        }
    }
}

// MARK: - Suggestions Dropdown

struct SuggestionsDropdown: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions.prefix(5), id: \.self) { suggestion in
                Button {
                    onSuggestionTap(suggestion)
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                        
                        Text(suggestion)
                            .foregroundColor(.primary)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, BrandConstants.Spacing.md)
                    .padding(.vertical, BrandConstants.Spacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
                
                if suggestion != suggestions.prefix(5).last {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.top, 4)
    }
}

// MARK: - Search Filters Row

struct SearchFiltersRow: View {
    let activeFilterCount: Int
    let currentFilters: SearchFilters
    let quickPresets: [QuickFilterPreset]
    let onFilterTap: () -> Void
    let onQuickFilterTap: (QuickFilterPreset) -> Void
    let onClearFilters: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BrandConstants.Spacing.sm) {
                // Main Filters Button
                FilterButton(
                    title: activeFilterCount > 0 ? "Filters (\(activeFilterCount))" : "Filters",
                    iconName: "slider.horizontal.3",
                    isSelected: activeFilterCount > 0,
                    action: onFilterTap
                )
                
                // Clear Filters (only show when there are active filters)
                if activeFilterCount > 0 {
                    FilterButton(
                        title: "Clear",
                        iconName: "xmark",
                        isSelected: false,
                        action: onClearFilters
                    )
                }
                
                // Quick Filter Presets
                ForEach(quickPresets) { preset in
                    FilterButton(
                        title: preset.name,
                        iconName: preset.iconName,
                        isSelected: false,
                        action: {
                            onQuickFilterTap(preset)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: BrandConstants.Spacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, BrandConstants.Spacing.md)
            .padding(.vertical, BrandConstants.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? BrandConstants.Colors.primary : Color(.secondarySystemBackground))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sort Options Row

struct SortOptionsRow: View {
    @Binding var selectedOption: SearchSortOption
    let resultCount: Int
    
    var body: some View {
        HStack {
            Text("\(resultCount) results")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Menu {
                ForEach(SearchSortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if selectedOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: BrandConstants.Spacing.xs) {
                    Image(systemName: selectedOption.iconName)
                        .font(.system(size: 14))
                    
                    Text("Sort: \(selectedOption.displayName)")
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(BrandConstants.Colors.primary)
            }
        }
    }
}

// MARK: - Search Loading View

struct SearchLoadingView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.lg) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(BrandConstants.Colors.primary)
            
            VStack(spacing: BrandConstants.Spacing.sm) {
                Text("Searching for \"\(query)\"")
                    .font(BrandConstants.Typography.headline)
                    .foregroundColor(.primary)
                
                Text("Finding the best classes, instructors, and venues...")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Search Error View

struct SearchErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.lg) {
            Spacer()
            
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            VStack(spacing: BrandConstants.Spacing.sm) {
                Text("Search Failed")
                    .font(BrandConstants.Typography.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .tint(BrandConstants.Colors.primary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Search Empty View

struct SearchEmptyView: View {
    let query: String
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: BrandConstants.Spacing.lg) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: BrandConstants.Spacing.sm) {
                Text("No Results Found")
                    .font(BrandConstants.Typography.title2)
                    .fontWeight(.bold)
                
                Text("We couldn't find any matches for \"\(query)\"")
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: BrandConstants.Spacing.md) {
                    Text("Try searching for:")
                        .font(BrandConstants.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BrandConstants.Spacing.sm) {
                        ForEach(suggestions.prefix(4), id: \.self) { suggestion in
                            Button(suggestion) {
                                onSuggestionTap(suggestion)
                            }
                            .padding(.horizontal, BrandConstants.Spacing.md)
                            .padding(.vertical, BrandConstants.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                                    .fill(BrandConstants.Colors.primary.opacity(0.1))
                            )
                            .foregroundColor(BrandConstants.Colors.primary)
                            .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.md)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Save Search Sheet

struct SaveSearchSheet: View {
    @Binding var searchName: String
    let query: String
    let filters: SearchFilters
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: BrandConstants.Spacing.lg) {
                VStack(alignment: .leading, spacing: BrandConstants.Spacing.sm) {
                    Text("Save this search for quick access later")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Search name", text: $searchName)
                        .textFieldStyle(.roundedBorder)
                    
                    VStack(alignment: .leading, spacing: BrandConstants.Spacing.xs) {
                        Text("Search details:")
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Query: \"\(query)\"")
                            .font(BrandConstants.Typography.caption)
                        
                        if filters.hasActiveFilters {
                            Text("Filters: \(filters.activeFilterCount) active")
                                .font(BrandConstants.Typography.caption)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: BrandConstants.CornerRadius.sm)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Save Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(searchName.isEmpty ? "Saved Search" : searchName)
                    }
                    .disabled(searchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}