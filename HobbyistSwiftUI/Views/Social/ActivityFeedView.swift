import SwiftUI

struct ActivityFeedView: View {
    @StateObject private var viewModel = ActivityFeedViewModel()
    @State private var selectedFilter = ActivityFilter.all
    
    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case following = "Following"
        case mentions = "Mentions"
        
        var icon: String {
            switch self {
            case .all: return "bell"
            case .following: return "person.2"
            case .mentions: return "at"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(ActivityFilter.allCases, id: \.self) { filter in
                        FilterTab(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                                viewModel.loadActivities(filter: filter)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .overlay(
                Divider()
                    .padding(.horizontal),
                alignment: .bottom
            )
            
            // Activity feed
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if filteredActivities.isEmpty {
                        EmptyActivityState(filter: selectedFilter)
                            .padding(.top, 60)
                    } else {
                        ForEach(groupedActivities, id: \.date) { group in
                            Section(header: DateHeader(date: group.date)) {
                                ForEach(group.activities) { activity in
                                    ActivityRow(activity: activity)
                                    Divider()
                                        .padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshActivities(filter: selectedFilter)
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadActivities(filter: selectedFilter)
        }
    }
    
    private var filteredActivities: [ActivityFeedItem] {
        switch selectedFilter {
        case .all:
            return viewModel.activities
        case .following:
            return viewModel.activities.filter { 
                // Filter for following activities
                $0.actionType == .followed || $0.actionType == .booked
            }
        case .mentions:
            return viewModel.activities.filter {
                // Filter for mentions (would check metadata in real app)
                $0.metadata?["mentioned"] != nil
            }
        }
    }
    
    private var groupedActivities: [(date: Date, activities: [ActivityFeedItem])] {
        let grouped = Dictionary(grouping: filteredActivities) { activity in
            Calendar.current.startOfDay(for: activity.createdAt)
        }
        
        return grouped.map { (key: $0.key, activities: $0.value) }
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, activities: $0.activities.sorted { $0.createdAt > $1.createdAt }) }
    }
}

// MARK: - Supporting Views

struct FilterTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.blue.opacity(0.1) : Color.clear
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct DateHeader: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityFeedItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Actor profile image
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(activity.actorName.prefix(2))
                        .font(.headline)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Activity description
                HStack {
                    Text(activityDescription)
                        .font(.subheadline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Additional content based on activity type
                if let targetName = activity.targetName {
                    Text(targetName)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Action buttons
                if activity.actionType == .reviewed || activity.actionType == .booked {
                    HStack(spacing: 20) {
                        Button(action: {}) {
                            Label("Like", systemImage: "heart")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {}) {
                            Label("Comment", systemImage: "bubble.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {}) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    private var activityDescription: String {
        let actorName = Text(activity.actorName).fontWeight(.semibold)
        
        switch activity.actionType {
        case .booked:
            return "\(activity.actorName) booked a class"
        case .reviewed:
            return "\(activity.actorName) left a review"
        case .followed:
            return "\(activity.actorName) started following"
        case .joined:
            return "\(activity.actorName) joined Hobbyist"
        case .created:
            return "\(activity.actorName) created a new class"
        case .achieved:
            return "\(activity.actorName) unlocked an achievement"
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: activity.createdAt, relativeTo: Date())
    }
}

struct EmptyActivityState: View {
    let filter: ActivityFeedView.ActivityFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var icon: String {
        switch filter {
        case .all:
            return "bell.slash"
        case .following:
            return "person.2.slash"
        case .mentions:
            return "at.badge.minus"
        }
    }
    
    private var title: String {
        switch filter {
        case .all:
            return "No Activity Yet"
        case .following:
            return "No Following Activity"
        case .mentions:
            return "No Mentions"
        }
    }
    
    private var message: String {
        switch filter {
        case .all:
            return "When you follow people and interact with classes, activity will appear here"
        case .following:
            return "Activity from people you follow will appear here"
        case .mentions:
            return "When someone mentions you, it will appear here"
        }
    }
}

#Preview {
    NavigationView {
        ActivityFeedView()
    }
}