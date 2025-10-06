import Foundation

extension String {

    func formattedTitle() -> String {
        return self.replacingOccurrences(of: "_", with: " ")
                   .capitalized
    }

    func localizedTitle() -> String {
        return NSLocalizedString(self, comment: "")
    }

    func underscoreToTitleCase() -> String {
        return self.replacingOccurrences(of: "_", with: " ")
                   .split(separator: " ")
                   .map { $0.capitalized }
                   .joined(separator: " ")
    }
}

struct LocalizedText {
    static func get(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }

    static func title(from underscoreKey: String) -> String {
        return NSLocalizedString(underscoreKey, comment: "")
    }
}

extension Text {
    init(localized key: String) {
        self.init(NSLocalizedString(key, comment: ""))
    }
}

extension Label where Title == Text, Icon == Image {
    init(localized titleKey: String, systemImage: String) {
        self.init(NSLocalizedString(titleKey, comment: ""), systemImage: systemImage)
    }
}

extension Button where Label == Text {
    init(localized titleKey: String, action: @escaping () -> Void) {
        self.init(NSLocalizedString(titleKey, comment: ""), action: action)
    }
}