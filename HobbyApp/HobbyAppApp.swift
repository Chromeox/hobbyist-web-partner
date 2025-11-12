import SwiftUI
// REMOVED: Packages no longer in project
// import GoogleSignIn
// import FacebookCore

// DISABLED: Using ProductionApp.swift as main entry point instead
// This file kept for reference only - has Facebook/Google integration
//@main
struct HobbyAppApp: App {
    init() {
        // DISABLED: Packages removed from project
        // configureGoogleSignIn()
        // configureFacebookSDK()

        // Configure app appearance
        configureAppearance()
        print("✅ HobbyApp initialized (disabled - reference only)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // DISABLED: Facebook package removed
                // .onOpenURL(perform: { url in
                //     ApplicationDelegate.shared.application(
                //         UIApplication.shared,
                //         open: url,
                //         sourceApplication: nil,
                //         annotation: [UIApplication.OpenURLOptionsKey.annotation]
                //     )
                // })
        }
    }

    // DISABLED: Google package removed
    // private func configureGoogleSignIn() {
    //     guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
    //           let plist = NSDictionary(contentsOfFile: path),
    //           let clientId = plist["CLIENT_ID"] as? String else {
    //         fatalError("No GoogleService-Info.plist file")
    //     }
    //     GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    //     print("✅ Google Sign In configured with client ID: \(clientId)")
    // }

    // DISABLED: Facebook package removed
    // private func configureFacebookSDK() {
    //     ApplicationDelegate.shared.application(
    //         UIApplication.shared,
    //         didFinishLaunchingWithOptions: nil
    //     )
    //     print("✅ Facebook SDK initialized")
    // }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}