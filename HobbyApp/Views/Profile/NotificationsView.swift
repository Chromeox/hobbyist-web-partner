import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingSettings = false
    @State private var selectedNotification: AppNotification?
    @State private var showingNotificationDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
            
            // Content
            Group {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingView
                } else if viewModel.filteredNotifications.isEmpty {
                    emptyView
                } else {
                    notificationsContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    Button(action: { Task { await viewModel.markAllAsRead() } }) {
                        Label("Mark All Read", systemImage: "envelope.open")
                    }
                    
                    Button(action: { Task { await viewModel.clearAll() } }) {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await viewModel.loadNotifications()
        }
        .onAppear {
            Task {
                await viewModel.loadNotifications()
            }
        }
        .sheet(isPresented: $showingSettings) {
            NotificationSettingsSheet()
        }
        .sheet(isPresented: $showingNotificationDetail) {
            if let notification = selectedNotification {
                NotificationDetailSheet(notification: notification) {
                    Task {
                        await viewModel.markAsRead(notification)
                    }
                }
            }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(NotificationFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        count: viewModel.notificationCount(for: filter),
                        isSelected: selectedFilter == filter,
                        isUnread: filter != .all && viewModel.hasUnreadNotifications(for: filter)
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(BrandConstants.Colors.surface)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading notifications...")
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedFilter == .all ? "bell.slash" : "bell")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(selectedFilter == .all ? "No Notifications" : "No \(selectedFilter.displayName)")
                .font(BrandConstants.Typography.title2)
                .fontWeight(.bold)
            
            Text(selectedFilter == .all ? 
                 "You're all caught up! New notifications will appear here." :
                 "No \(selectedFilter.displayName.lowercased()) notifications at the moment.")
                .font(BrandConstants.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var notificationsContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.groupedNotifications, id: \.date) { group in
                    NotificationGroupView(
                        group: group,
                        onNotificationTap: { notification in
                            selectedNotification = notification
                            showingNotificationDetail = true
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                        },
                        onMarkAsRead: { notification in
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                        },
                        onDelete: { notification in
                            Task {
                                await viewModel.deleteNotification(notification)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let isUnread: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    ZStack {
                        Text("\(count)")
                            .font(BrandConstants.Typography.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.white.opacity(0.3) : (isUnread ? Color.red : Color.gray.opacity(0.3)))
                            .cornerRadius(BrandConstants.CornerRadius.sm)
                        
                        if isUnread && !isSelected {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 12, y: -8)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? BrandConstants.Colors.primary : BrandConstants.Colors.background)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(BrandConstants.CornerRadius.full)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationGroupView: View {
    let group: NotificationGroup
    let onNotificationTap: (AppNotification) -> Void
    let onMarkAsRead: (AppNotification) -> Void
    let onDelete: (AppNotification) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(group.displayDate)
                    .font(BrandConstants.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if group.unreadCount > 0 {
                    Text("\(group.unreadCount) unread")
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(BrandConstants.CornerRadius.sm)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Notifications
            ForEach(group.notifications) { notification in
                NotificationRowView(
                    notification: notification,
                    onTap: { onNotificationTap(notification) },
                    onMarkAsRead: { onMarkAsRead(notification) },
                    onDelete: { onDelete(notification) }
                )
                .padding(.horizontal)
            }
        }
        .background(BrandConstants.Colors.surface)
    }
}

struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: notification.type.iconName)
                            .foregroundColor(notification.type.color)
                            .font(BrandConstants.Typography.subheadline)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(BrandConstants.Typography.subheadline)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(BrandConstants.Colors.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    if let message = notification.message {
                        Text(message)
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack {
                        Text(notification.timeAgo)
                            .font(BrandConstants.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let actionText = notification.actionText {
                            Text(actionText)
                                .font(BrandConstants.Typography.caption)
                                .foregroundColor(BrandConstants.Colors.primary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(notification.isRead ? BrandConstants.Colors.surface : BrandConstants.Colors.primary.opacity(0.05))
            .cornerRadius(BrandConstants.CornerRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete") {
                onDelete()
            }
            .tint(.red)
            
            if !notification.isRead {
                Button("Mark Read") {
                    onMarkAsRead()
                }
                .tint(.blue)
            }
        }
    }
}

struct NotificationSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = NotificationSettings()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notification Types") {
                    Toggle("Class Reminders", isOn: $settings.classReminders)
                    Toggle("Booking Confirmations", isOn: $settings.bookingConfirmations)
                    Toggle("Instructor Messages", isOn: $settings.instructorMessages)
                    Toggle("New Classes", isOn: $settings.newClasses)
                    Toggle("Promotions", isOn: $settings.promotions)
                    Toggle("System Updates", isOn: $settings.systemUpdates)
                }
                
                Section("Timing") {
                    Picker("Class Reminders", selection: $settings.reminderTiming) {
                        Text("15 minutes before").tag(15)
                        Text("30 minutes before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("2 hours before").tag(120)
                    }
                    
                    Toggle("Quiet Hours (9 PM - 7 AM)", isOn: $settings.quietHours)
                }
                
                Section("Delivery") {
                    Toggle("Push Notifications", isOn: $settings.pushNotifications)
                    Toggle("Email Notifications", isOn: $settings.emailNotifications)
                    Toggle("SMS Notifications", isOn: $settings.smsNotifications)
                }
                
                Section {
                    Button("Request Notification Permission") {
                        requestNotificationPermission()
                    }
                    
                    Button("Open Settings App") {
                        openSettingsApp()
                    }
                } footer: {
                    Text("If notifications aren't working, you may need to enable them in your device settings.")
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                settings.pushNotifications = granted
            }
        }
    }
    
    private func openSettingsApp() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func saveSettings() {
        // Save settings to UserDefaults or API
        UserDefaults.standard.set(settings.classReminders, forKey: "notification_class_reminders")
        UserDefaults.standard.set(settings.bookingConfirmations, forKey: "notification_booking_confirmations")
        // ... save other settings
    }
}

struct NotificationDetailSheet: View {
    let notification: AppNotification
    let onMarkAsRead: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(notification.type.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: notification.type.iconName)
                                        .foregroundColor(notification.type.color)
                                        .font(BrandConstants.Typography.title3)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.type.displayName)
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(notification.createdAt, style: .relative)
                                    .font(BrandConstants.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(notification.title)
                            .font(BrandConstants.Typography.title2)
                            .fontWeight(.bold)
                    }
                    
                    // Message
                    if let message = notification.message {
                        Text(message)
                            .font(BrandConstants.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Additional content based on type
                    if let data = notification.data {
                        notificationTypeContent(for: notification.type, data: data)
                    }
                    
                    // Actions
                    if let actionText = notification.actionText {
                        Button(actionText) {
                            handleNotificationAction(notification)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BrandConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(BrandConstants.CornerRadius.md)
                        .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !notification.isRead {
                    onMarkAsRead()
                }
            }
        }
    }
    
    @ViewBuilder
    private func notificationTypeContent(for type: NotificationType, data: [String: Any]) -> some View {
        switch type {
        case .classReminder:
            if let className = data["className"] as? String,
               let startTime = data["startTime"] as? String {
                classReminderContent(className: className, startTime: startTime)
            }
        case .bookingConfirmation:
            if let className = data["className"] as? String,
               let venue = data["venue"] as? String {
                bookingConfirmationContent(className: className, venue: venue)
            }
        case .instructorMessage, .newClass, .promotion, .systemUpdate:
            EmptyView()
        }
    }
    
    private func classReminderContent(className: String, startTime: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Class Details")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .frame(width: 20)
                    Text(className)
                        .font(BrandConstants.Typography.subheadline)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .frame(width: 20)
                    Text(startTime)
                        .font(BrandConstants.Typography.subheadline)
                }
            }
        }
        .padding()
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
    
    private func bookingConfirmationContent(className: String, venue: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Details")
                .font(BrandConstants.Typography.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    Text("Confirmed")
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .frame(width: 20)
                    Text(className)
                        .font(BrandConstants.Typography.subheadline)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(BrandConstants.Colors.primary)
                        .frame(width: 20)
                    Text(venue)
                        .font(BrandConstants.Typography.subheadline)
                }
            }
        }
        .padding()
        .background(BrandConstants.Colors.background)
        .cornerRadius(BrandConstants.CornerRadius.md)
    }
    
    private func handleNotificationAction(_ notification: AppNotification) {
        // Handle different notification actions
        switch notification.type {
        case .classReminder:
            // Navigate to class details or my bookings
            break
        case .bookingConfirmation:
            // Navigate to booking details
            break
        case .newClass:
            // Navigate to class details
            break
        case .promotion:
            // Navigate to store or promotional content
            break
        default:
            break
        }
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}