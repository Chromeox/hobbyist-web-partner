import SwiftUI
import MapKit
import UIKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var hapticService: HapticFeedbackService
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    searchSection
                    categoriesSection
                    featuredSection
                    instructorsSection
                    upcomingClassesSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover Hobbies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        hapticService.playLight()
                        showingFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FiltersView(viewModel: viewModel)
            }
        }
    }

    private var searchSection: some View {
        SearchBarView(text: $searchText)
            .padding(.horizontal)
            .onChange(of: searchText) { _ in
                hapticService.playLight()
                viewModel.searchClasses(query: searchText)
            }
    }

    private var categoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    HomeCategoryChip(
                        title: category.name,
                        icon: category.icon,
                        isSelected: selectedCategory == category.name,
                        action: {
                            hapticService.playSelection()
                            if selectedCategory == category.name {
                                selectedCategory = nil
                            } else {
                                selectedCategory = category.name
                            }
                            viewModel.filterByCategory(selectedCategory)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.featuredClasses.isEmpty {
                SectionHeader(
                    title: "Featured Classes",
                    actionTitle: "See All",
                    action: {
                        hapticService.playLight()
                    }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.featuredClasses) { classItem in
                            NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                FeaturedClassCard(classItem: classItem)
                            }
                            .simultaneousGesture(TapGesture().onEnded { _ in
                                hapticService.playMedium()
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var instructorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.popularInstructors.isEmpty {
                SectionHeader(
                    title: "Popular Instructors",
                    actionTitle: "See All",
                    action: {
                        hapticService.playLight()
                    }
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.popularInstructors) { instructor in
                            InstructorCardView(instructor: instructor)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var upcomingClassesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.upcomingClasses.isEmpty {
                SectionHeader(
                    title: "Starting Soon",
                    actionTitle: "View Schedule",
                    action: {
                        hapticService.playLight()
                    }
                )

                VStack(spacing: 12) {
                    ForEach(viewModel.upcomingClasses) { classItem in
                        NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                            UpcomingClassRow(classItem: classItem)
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            hapticService.playMedium()
                        })
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Search Bar Component
struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search classes, instructors...", text: $text)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Category Chip Component
struct HomeCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// Section Header Component
struct SectionHeader: View {
    let title: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(actionTitle, action: action)
                .font(.caption)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal)
    }
}

// Featured Class Card Component
struct FeaturedClassCard: View {
    let classItem: ClassItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: URL(string: classItem.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 280, height: 160)
            .clipped()
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text(classItem.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(classItem.instructor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(classItem.price)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)

                    Spacer()

                    Text(classItem.spotsLeft)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(width: 280)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Instructor Card Component
struct InstructorCardView: View {
    let instructor: InstructorCard

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.accentColor.opacity(0.3), Color.accentColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(instructor.initials)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            Text(instructor.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text(instructor.rating)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100)
    }
}

// Upcoming Class Row Component
struct UpcomingClassRow: View {
    let classItem: ClassItem

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: classItem.icon)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(classItem.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(classItem.instructor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(classItem.price)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)

                    Spacer()

                    Text(classItem.spotsLeft)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Filters View
struct FiltersView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var hapticService: HapticFeedbackService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Price Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Price Range")
                            .font(.headline)

                        HStack {
                            Text("$\(Int(viewModel.minPrice))")
                            Slider(value: $viewModel.minPrice, in: 0...200)
                                .onChange(of: viewModel.minPrice) { _ in
                                    hapticService.playLight()
                                }
                            Text("$\(Int(viewModel.maxPrice))")
                            Slider(value: $viewModel.maxPrice, in: 0...200)
                                .onChange(of: viewModel.maxPrice) { _ in
                                    hapticService.playLight()
                                }
                        }
                    }

                    // Distance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Distance")
                            .font(.headline)

                        Picker("Distance", selection: $viewModel.selectedDistance) {
                            Text("2 miles").tag(2)
                            Text("5 miles").tag(5)
                            Text("10 miles").tag(10)
                            Text("25 miles").tag(25)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: viewModel.selectedDistance) { _ in
                            hapticService.playSelection()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        hapticService.playLight()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(HapticFeedbackService.shared)
    }
}