import Foundation

// MARK: - Feature Flag System for Safe Incremental Rollout
@MainActor
final class FeatureFlagManager: ObservableObject {
    static let shared = FeatureFlagManager()

    // Published properties for UI binding
    @Published private(set) var flags: [FeatureFlag: Bool] = [:]

    private init() {
        loadFeatureFlags()
    }

    // MARK: - Feature Flags

    enum FeatureFlag: String, CaseIterable {
        case onboardingModule = "onboarding_module"
        case profileModule = "profile_module"
        case discoveryModule = "discovery_module"
        case settingsModule = "settings_module"
        case gamificationModule = "gamification_module"

        var displayName: String {
            switch self {
            case .onboardingModule: return "Onboarding Flow"
            case .profileModule: return "Enhanced Profile"
            case .discoveryModule: return "Discovery & Search"
            case .settingsModule: return "Settings Management"
            case .gamificationModule: return "Gamification System"
            }
        }

        var defaultValue: Bool {
            switch self {
            case .onboardingModule: return true   // Onboarding module is complete
            case .profileModule: return true     // Profile module is complete
            case .discoveryModule: return false
            case .settingsModule: return false
            case .gamificationModule: return false
            }
        }
    }

    // MARK: - Public API

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        return flags[flag] ?? flag.defaultValue
    }

    func setFlag(_ flag: FeatureFlag, enabled: Bool) {
        flags[flag] = enabled
        saveFeatureFlags()

        // Log feature flag changes for debugging
        print("🏁 Feature flag '\(flag.displayName)' \(enabled ? "enabled" : "disabled")")
    }

    func resetToDefaults() {
        for flag in FeatureFlag.allCases {
            flags[flag] = flag.defaultValue
        }
        saveFeatureFlags()
        print("🏁 All feature flags reset to defaults")
    }

    // MARK: - Debug Interface

    var debugDescription: String {
        let flagStatuses = FeatureFlag.allCases.map { flag in
            let status = isEnabled(flag) ? "✅" : "❌"
            return "\(status) \(flag.displayName)"
        }
        return "Feature Flags:\n" + flagStatuses.joined(separator: "\n")
    }

    // MARK: - Persistence

    private func loadFeatureFlags() {
        for flag in FeatureFlag.allCases {
            let key = "feature_flag_\(flag.rawValue)"
            if UserDefaults.standard.object(forKey: key) != nil {
                flags[flag] = UserDefaults.standard.bool(forKey: key)
            } else {
                flags[flag] = flag.defaultValue
            }
        }

        print("🏁 Loaded feature flags: \(flags.count) flags")
    }

    private func saveFeatureFlags() {
        for (flag, isEnabled) in flags {
            let key = "feature_flag_\(flag.rawValue)"
            UserDefaults.standard.set(isEnabled, forKey: key)
        }
    }
}

// MARK: - Debug View for Development
#if DEBUG
import SwiftUI

struct FeatureFlagDebugView: View {
    @ObservedObject var flagManager = FeatureFlagManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Feature Modules") {
                    ForEach(FeatureFlagManager.FeatureFlag.allCases, id: \.self) { flag in
                        Toggle(flag.displayName, isOn: Binding(
                            get: { flagManager.isEnabled(flag) },
                            set: { flagManager.setFlag(flag, enabled: $0) }
                        ))
                    }
                }

                Section("Actions") {
                    Button("Reset to Defaults") {
                        flagManager.resetToDefaults()
                    }
                    .foregroundColor(.red)
                }

                Section("Debug Info") {
                    Text(flagManager.debugDescription)
                        .font(.monospaced(.caption)())
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Feature Flags")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FeatureFlagDebugView()
}
#endif