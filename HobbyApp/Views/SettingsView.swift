import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel: SettingsViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingDataExport = false
    @State private var exportedDataURL: URL?
    
    init() {
        let profileVM = ProfileViewModel()
        _viewModel = StateObject(wrappedValue: SettingsViewModel(profileViewModel: profileVM))
        _profileViewModel = StateObject(wrappedValue: profileVM)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    profileSectionView
                }
                
                // Notifications Section
                Section("Notifications") {
                    notificationSettingsView
                }
                
                // Privacy & Location Section
                Section("Privacy & Location") {
                    privacySettingsView
                }
                
                // Appearance Section
                Section("Appearance") {
                    appearanceSettingsView
                }
                
                // Preferences Section
                Section("Class Preferences") {
                    preferencesView
                }
                
                // Data & Storage Section
                Section("Data & Storage") {
                    dataStorageView
                }
                
                // Support Section
                Section("Support") {
                    supportView
                }
                
                // About Section
                Section("About") {
                    aboutView
                }
                
                // Account Actions Section
                Section("Account Actions") {
                    accountActionsView
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.profileViewModel.loadProfile()
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.successMessage = nil
                }
            } message: {
                if let message = viewModel.successMessage {
                    Text(message)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .alert("Sign Out", isPresented: $viewModel.showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task { await viewModel.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $viewModel.showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .sheet(isPresented: $showingDataExport) {
                if let url = exportedDataURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
    }
}

// MARK: - View Components

extension SettingsView {
    
    private var profileSectionView: some View {
        HStack {
            AsyncImage(url: URL(string: authManager.currentUser?.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(.headline)
                Text(authManager.currentUser?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            NavigationLink(destination: ProfileView().environmentObject(profileViewModel)) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var notificationSettingsView: some View {
        Group {
            Toggle("Push Notifications", isOn: Binding(
                get: { viewModel.notificationSettings.pushNotifications },
                set: { value in
                    var settings = viewModel.notificationSettings
                    settings.pushNotifications = value
                    viewModel.updateNotificationSettings(settings)
                }
            ))
            
            Toggle("Email Notifications", isOn: Binding(
                get: { viewModel.notificationSettings.emailNotifications },
                set: { value in
                    var settings = viewModel.notificationSettings
                    settings.emailNotifications = value
                    viewModel.updateNotificationSettings(settings)
                }
            ))
            
            Toggle("Class Reminders", isOn: Binding(
                get: { viewModel.notificationSettings.classReminders },
                set: { value in
                    var settings = viewModel.notificationSettings
                    settings.classReminders = value
                    viewModel.updateNotificationSettings(settings)
                }
            ))
            
            Toggle("Marketing Emails", isOn: Binding(
                get: { viewModel.notificationSettings.marketingEmails },
                set: { value in
                    var settings = viewModel.notificationSettings
                    settings.marketingEmails = value
                    viewModel.updateNotificationSettings(settings)
                }
            ))
        }
    }
    
    private var privacySettingsView: some View {
        Group {
            NavigationLink(destination: PrivacyPolicyView()) {
                Label("Privacy Policy", systemImage: "lock.doc")
            }
            
            NavigationLink(destination: TermsOfServiceView()) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            
            Button {
                openLocationSettings()
            } label: {
                Label("Location Settings", systemImage: "location")
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var appearanceSettingsView: some View {
        Group {
            HStack {
                Label("Language", systemImage: "globe")
                Spacer()
                Picker("Language", selection: Binding(
                    get: { viewModel.userPreferences.language },
                    set: { value in
                        var preferences = viewModel.userPreferences
                        preferences.language = value
                        viewModel.updateUserPreferences(preferences)
                    }
                )) {
                    Text("English").tag("en")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Italian").tag("it")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Toggle(isOn: $viewModel.isDarkModeEnabled) {
                Label("Dark Mode", systemImage: "moon")
            }
        }
    }
    
    private var preferencesView: some View {
        Group {
            NavigationLink(destination: ClassPreferencesView(preferences: $viewModel.userPreferences)) {
                Label("Class Categories", systemImage: "list.bullet")
            }
            
            NavigationLink(destination: TimePreferencesView(preferences: $viewModel.userPreferences)) {
                Label("Preferred Times", systemImage: "clock")
            }
            
            HStack {
                Label("Max Price", systemImage: "dollarsign.circle")
                Spacer()
                Text("$\(Int(viewModel.userPreferences.maxPrice))")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var dataStorageView: some View {
        Group {
            Button {
                Task {
                    if let url = await viewModel.exportUserData() {
                        exportedDataURL = url
                        showingDataExport = true
                    }
                }
            } label: {
                Label("Export My Data", systemImage: "square.and.arrow.up")
                    .foregroundColor(.primary)
            }
            
            Button {
                viewModel.clearCache()
            } label: {
                Label("Clear Cache", systemImage: "trash")
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var supportView: some View {
        Group {
            Link(destination: URL(string: "https://hobbyist.app/help")!) {
                Label("Help Center", systemImage: "questionmark.circle")
            }
            
            Button {
                sendSupportEmail()
            } label: {
                Label("Contact Support", systemImage: "envelope")
                    .foregroundColor(.primary)
            }
            
            Button {
                reportBug()
            } label: {
                Label("Report a Bug", systemImage: "ladybug")
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var aboutView: some View {
        Group {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(viewModel.fullVersionString)
                    .foregroundColor(.secondary)
            }
            
            NavigationLink(destination: LicensesView()) {
                Label("Third-Party Licenses", systemImage: "doc.badge.gearshape")
            }
            
            NavigationLink(destination: AcknowledgmentsView()) {
                Label("Acknowledgments", systemImage: "heart")
            }
        }
    }
    
    private var accountActionsView: some View {
        Group {
            Button {
                viewModel.showingSignOutAlert = true
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
                    .foregroundColor(.orange)
            }
            
            Button {
                viewModel.showingDeleteAccountAlert = true
            } label: {
                Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Helper Functions

extension SettingsView {
    
    private func openLocationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func sendSupportEmail() {
        let email = "support@hobbyist.app"
        let subject = "Support Request - iOS App"
        let body = """
        App Version: \(viewModel.fullVersionString)
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        
        Please describe your issue:
        
        """
        
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func reportBug() {
        let email = "bugs@hobbyist.app"
        let subject = "Bug Report - iOS App"
        let body = """
        App Version: \(viewModel.fullVersionString)
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        
        Steps to reproduce:
        1. 
        2. 
        3. 
        
        Expected behavior:
        
        
        Actual behavior:
        
        
        Additional notes:
        
        """
        
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(AuthenticationManager.shared)
        }
    }
}