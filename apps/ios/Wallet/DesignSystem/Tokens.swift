import SwiftUI

/// Single source for spacing, radii, motion and colour. Brand name lives in `Brand`.
enum Brand { static let name = "Wallet" }

enum Space {
    static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 16, l: CGFloat = 24, xl: CGFloat = 32
}

enum Radius { static let card: CGFloat = 20, control: CGFloat = 12 }

enum Motion {
    static var spring: Animation { .spring(response: 0.38, dampingFraction: 0.86) }
    /// Returns nil (no animation) when Reduce Motion is on.
    static func animation(_ base: Animation, reduceMotion: Bool) -> Animation? { reduceMotion ? nil : base }
}

enum Palette {
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)

    /// Card colours are dark enough for white text.
    static func card(_ c: PassColor) -> Color {
        switch c {
        case .ink: Color(red: 0.07, green: 0.09, blue: 0.15)
        case .indigo: Color(red: 0.22, green: 0.19, blue: 0.64)
        case .teal: Color(red: 0.06, green: 0.46, blue: 0.43)
        case .coral: Color(red: 0.76, green: 0.25, blue: 0.05)
        case .amber: Color(red: 0.55, green: 0.33, blue: 0.02)
        case .forest: Color(red: 0.09, green: 0.40, blue: 0.20)
        case .slate: Color(red: 0.20, green: 0.25, blue: 0.33)
        case .plum: Color(red: 0.42, green: 0.13, blue: 0.66)
        }
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var scheme: ColorScheme? { self == .light ? .light : self == .dark ? .dark : nil }
    var title: LocalizedStringKey {
        switch self { case .system: "System"; case .light: "Light"; case .dark: "Dark" }
    }
}

extension PassCategory {
    var plainTitle: String {
        switch self {
        case .loyalty: String(localized: "Loyalty")
        case .membership: String(localized: "Membership")
        case .eventTicket: String(localized: "Event ticket")
        case .boardingPass: String(localized: "Boarding pass")
        case .general: String(localized: "General")
        case .documentReference: String(localized: "Document reference")
        case .paymentCardRepresentation: String(localized: "Card (visual only)")
        }
    }
    var symbol: String {
        switch self {
        case .loyalty: "star.circle"
        case .membership: "person.crop.rectangle"
        case .eventTicket: "ticket"
        case .boardingPass: "airplane"
        case .general: "rectangle.stack"
        case .documentReference: "doc.text"
        case .paymentCardRepresentation: "creditcard"
        }
    }
}

extension TrustLevel {
    var label: String {
        switch self {
        case .sample: String(localized: "Sample")
        case .custom: String(localized: "Custom")
        case .imported: String(localized: "Imported")
        case .verifiedCredential: String(localized: "Verified")
        case .paymentCredential: String(localized: "Payment")
        }
    }
    var explanation: String {
        switch self {
        case .sample: String(localized: "Fictional demo data. Not a real pass.")
        case .custom: String(localized: "Created by you. The issuer has not verified it.")
        case .imported: String(localized: "Imported from elsewhere. Not verified.")
        case .verifiedCredential: String(localized: "Verified with the issuer.")
        case .paymentCredential: String(localized: "Managed by an authorised payment provider.")
        }
    }
}

extension PassValidity.State {
    var label: String? {
        switch self {
        case .valid: nil
        case .expiringSoon: String(localized: "Expires soon")
        case .expired: String(localized: "Expired")
        case .notYetValid: String(localized: "Not yet valid")
        }
    }
}

extension ValidationError {
    var message: String {
        switch code {
        case .required: String(localized: "This field is required.")
        case .tooLong: String(localized: "This is too long.")
        case .invalidCharacters: String(localized: "Contains characters that aren't allowed.")
        case .invalidRange: String(localized: "Expiry must be after the start date.")
        case .tooMany: String(localized: "Too many details.")
        }
    }
}
