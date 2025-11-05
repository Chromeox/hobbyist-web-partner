import SwiftUI

struct AccountSettingsView: View {
    @StateObject private var viewModel = AccountSettingsViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingDeleteAlert = false
    @State private var showingLogoutAlert = false
    @State private var showingChangePasswordSheet = false
    @State private var showingPrivacySheet = false
    @State private var showingDataExportSheet = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                profileSection
                
                // Account Security
                securitySection
                
                // Privacy & Data
                privacySection
                
                // Connected Accounts
                connectedAccountsSection
                
                // Account Actions
                accountActionsSection
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadAccountInfo()
            }
            .onAppear {
                Task {
                    await viewModel.loadAccountInfo()
                }
            }
            .sheet(isPresented: $showingChangePasswordSheet) {
                ChangePasswordSheet()
            }
            .sheet(isPresented: $showingPrivacySheet) {
                PrivacySettingsSheet()
            }
            .sheet(isPresented: $showingDataExportSheet) {
                DataExportSheet()
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data, bookings, and account information will be permanently deleted.")
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private var profileSection: some View {
        Section("Profile Information") {
            // Profile Picture
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: viewModel.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(BrandConstants.Colors.primary.opacity(0.3))
                        .overlay(
                            Text(viewModel.initials)
                                .font(BrandConstants.Typography.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(BrandConstants.Colors.primary)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.fullName)
                        .font(BrandConstants.Typography.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.email)
                        .font(BrandConstants.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Edit") {
                    // Handle profile edit
                }
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(BrandConstants.Colors.primary)
            }
            .padding(.vertical, 4)
            
            // Account Stats
            VStack(spacing: 12) {
                AccountStatRow(label: "Member since", value: viewModel.memberSince)
                AccountStatRow(label: "Classes attended", value: "\(viewModel.classesAttended)")
                AccountStatRow(label: "Total spent", value: viewModel.totalSpent)
                AccountStatRow(label: "Favorite category", value: viewModel.favoriteCategory)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var securitySection: some View {
        Section("Security") {
            Button(action: { showingChangePasswordSheet = true }) {
                SettingsRowView(
                    icon: "lock.fill",
                    title: "Change Password",
                    subtitle: "Last changed 3 months ago",
                    showChevron: true
                )
            }
            
            NavigationLink(destination: TwoFactorAuthView()) {
                SettingsRowView(
                    icon: "shield.fill",
                    title: "Two-Factor Authentication",
                    subtitle: viewModel.twoFactorEnabled ? "Enabled" : "Disabled",
                    showChevron: true,
                    accentColor: viewModel.twoFactorEnabled ? .green : .orange
                )
            }
            
            NavigationLink(destination: LoginActivityView()) {
                SettingsRowView(
                    icon: "clock.fill",
                    title: "Login Activity",
                    subtitle: "View recent sign-ins",
                    showChevron: true
                )
            }
            
            NavigationLink(destination: ConnectedDevicesView()) {
                SettingsRowView(
                    icon: "iphone",
                    title: "Connected Devices",
                    subtitle: "\(viewModel.connectedDevicesCount) devices",
                    showChevron: true
                )
            }
        }
    }
    
    private var privacySection: some View {
        Section("Privacy & Data") {
            Button(action: { showingPrivacySheet = true }) {
                SettingsRowView(
                    icon: "eye.slash.fill",
                    title: "Privacy Settings",
                    subtitle: "Control your privacy preferences",
                    showChevron: true
                )
            }
            
            Button(action: { showingDataExportSheet = true }) {
                SettingsRowView(
                    icon: "square.and.arrow.down.fill",
                    title: "Download Your Data",
                    subtitle: "Export all your account data",
                    showChevron: true
                )
            }
            
            NavigationLink(destination: DataUsageView()) {
                SettingsRowView(
                    icon: "chart.bar.fill",
                    title: "Data Usage",
                    subtitle: "See how your data is used",
                    showChevron: true
                )
            }
            
            Toggle(isOn: $viewModel.analyticsEnabled) {
                SettingsRowView(
                    icon: "chart.pie.fill",
                    title: "Analytics",
                    subtitle: "Help improve the app with usage data"
                )
            }
            .tint(BrandConstants.Colors.primary)
        }
    }
    
    private var connectedAccountsSection: some View {
        Section("Connected Accounts") {
            ConnectedAccountRow(
                platform: "Google",
                icon: "globe",
                isConnected: viewModel.googleConnected,
                onToggle: { await viewModel.toggleGoogleConnection() }
            )
            
            ConnectedAccountRow(
                platform: "Apple",
                icon: "applelogo",
                isConnected: viewModel.appleConnected,
                onToggle: { await viewModel.toggleAppleConnection() }
            )
            
            ConnectedAccountRow(
                platform: "Facebook",
                icon: "person.2.fill",
                isConnected: viewModel.facebookConnected,
                onToggle: { await viewModel.toggleFacebookConnection() }
            )
        }
    }
    
    private var accountActionsSection: some View {
        Section("Account Actions") {
            Button(action: { showingLogoutAlert = true }) {
                SettingsRowView(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Sign Out",
                    subtitle: "Sign out of your account",
                    accentColor: .orange
                )
            }
            
            Button(action: { showingDeleteAlert = true }) {
                SettingsRowView(
                    icon: "trash.fill",
                    title: "Delete Account",
                    subtitle: "Permanently delete your account",
                    accentColor: .red
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct AccountStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(BrandConstants.Typography.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(BrandConstants.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String?
    var showChevron: Bool = false
    var accentColor: Color = BrandConstants.Colors.primary
    
    init(icon: String, title: String, subtitle: String? = nil, showChevron: Bool = false, accentColor: Color = BrandConstants.Colors.primary) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.accentColor = accentColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(accentColor)
                .font(BrandConstants.Typography.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(BrandConstants.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(BrandConstants.Typography.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ConnectedAccountRow: View {
    let platform: String
    let icon: String
    let isConnected: Bool
    let onToggle: () async -> Void
    @State private var isToggling = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isConnected ? .green : .gray)
                .font(BrandConstants.Typography.subheadline)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(BrandConstants.Typography.subheadline)
                    .foregroundColor(.primary)
                
                Text(isConnected ? "Connected" : "Not connected")
                    .font(BrandConstants.Typography.caption)
                    .foregroundColor(isConnected ? .green : .secondary)
            }
            
            Spacer()
            
            if isToggling {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(isConnected ? "Disconnect" : "Connect") {
                    isToggling = true
                    Task {
                        await onToggle()
                        isToggling = false
                    }
                }
                .font(BrandConstants.Typography.caption)
                .foregroundColor(isConnected ? .red : BrandConstants.Colors.primary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    SecureField("Enter current password", text: $currentPassword)
                        .textContentType(.password)
                }
                
                Section("New Password") {
                    SecureField("Enter new password", text: $newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(BrandConstants.Typography.caption)
                    }
                }
                
                Section {
                    Button("Change Password") {
                        changePassword()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isFormValid || isLoading)
                    .foregroundColor(isFormValid ? BrandConstants.Colors.primary : .gray)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        newPassword.count >= 8
    }
    
    private func changePassword() {
        isLoading = true
        errorMessage = ""
        
        // Simulate password change
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // Simulate success
            dismiss()
        }
    }
}

struct PrivacySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileVisible = true
    @State private var activityVisible = false
    @State private var contactsAccess = true
    @State private var locationTracking = false
    @State private var marketingEmails = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Visibility") {
                    Toggle("Profile visible to others", isOn: $profileVisible)
                    Toggle("Show activity status", isOn: $activityVisible)
                }
                
                Section("Data Collection") {
                    Toggle("Allow contacts access", isOn: $contactsAccess)
                    Toggle("Location tracking", isOn: $locationTracking)
                }
                
                Section("Communications") {
                    Toggle("Marketing emails", isOn: $marketingEmails)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DataExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDataTypes: Set<DataType> = []
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Data to Export") {
                    ForEach(DataType.allCases, id: \.self) { dataType in
                        HStack {
                            Text(dataType.displayName)
                            Spacer()
                            if selectedDataTypes.contains(dataType) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BrandConstants.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedDataTypes.contains(dataType) {
                                selectedDataTypes.remove(dataType)
                            } else {
                                selectedDataTypes.insert(dataType)
                            }
                        }
                    }
                }
                
                Section {
                    Button(isExporting ? "Preparing Export..." : "Export Data") {
                        exportData()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(selectedDataTypes.isEmpty || isExporting)
                    .foregroundColor(selectedDataTypes.isEmpty ? .gray : BrandConstants.Colors.primary)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            // Handle export completion
            dismiss()
        }
    }
}

enum DataType: String, CaseIterable {
    case profile = "profile"
    case bookings = "bookings"
    case reviews = "reviews"
    case favorites = "favorites"
    case messages = "messages"
    
    var displayName: String {
        switch self {
        case .profile:
            return "Profile Information"
        case .bookings:
            return "Booking History"
        case .reviews:
            return "Reviews & Ratings"
        case .favorites:
            return "Favorite Classes"
        case .messages:
            return "Messages"
        }
    }
}

// Placeholder views for navigation destinations
struct TwoFactorAuthView: View {
    var body: some View {
        Text("Two-Factor Authentication")
            .navigationTitle("2FA")
    }
}

struct LoginActivityView: View {
    var body: some View {
        Text("Login Activity")
            .navigationTitle("Login Activity")
    }
}

struct ConnectedDevicesView: View {
    var body: some View {
        Text("Connected Devices")
            .navigationTitle("Devices")
    }
}

struct DataUsageView: View {
    var body: some View {
        Text("Data Usage")
            .navigationTitle("Data Usage")
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
            .environmentObject(AuthenticationManager.shared)
    }
}