import Foundation

public enum PassCategory: String, Codable, CaseIterable, Sendable {
    case loyalty, membership, eventTicket, boardingPass, general
    case documentReference, paymentCardRepresentation
}

/// How much we know about where a pass came from. Levels are never converted
/// into one another implicitly; see docs/decisions/0003-trust-model.md.
public enum TrustLevel: String, Codable, Sendable {
    case sample              // fictional demo data
    case custom              // typed in by the user, issuer not verified
    case imported            // came from outside, not verified
    case verifiedCredential  // verified via a documented mechanism (none exist yet)
    case paymentCredential   // managed by an authorised payment mechanism (none exist yet)
}

public enum PassStatus: String, Codable, Sendable { case active, archived }

public enum PassColor: String, Codable, CaseIterable, Sendable {
    case ink, indigo, teal, coral, amber, forest, slate, plum
}

public struct PassIssuer: Codable, Hashable, Sendable {
    public var name: String
    public init(name: String) { self.name = name }
}

public struct PassValidity: Codable, Hashable, Sendable {
    public var validFrom: Date?
    public var expiresAt: Date?

    public enum State: String, Sendable { case notYetValid, valid, expiringSoon, expired }
    public static let expiringSoonWindow: TimeInterval = 30 * 24 * 60 * 60

    public init(validFrom: Date? = nil, expiresAt: Date? = nil) {
        self.validFrom = validFrom
        self.expiresAt = expiresAt
    }

    /// A pass is valid from `validFrom` (inclusive) until `expiresAt` (exclusive).
    public func state(at now: Date) -> State {
        if let from = validFrom, now < from { return .notYetValid }
        if let end = expiresAt {
            if now >= end { return .expired }
            if end.timeIntervalSince(now) <= Self.expiringSoonWindow { return .expiringSoon }
        }
        return .valid
    }
}

public struct PassField: Codable, Hashable, Sendable {
    public var label: String
    public var value: String
    public init(label: String, value: String) { self.label = label; self.value = value }
}

public struct WalletPass: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var issuer: PassIssuer
    public var category: PassCategory
    public var trust: TrustLevel
    public var status: PassStatus
    public var validity: PassValidity
    public var color: PassColor
    public var identifier: String?
    public var fields: [PassField]
    /// Text encoded into the pass's QR code. Never put secrets here.
    public var codePayload: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), title: String, issuer: PassIssuer, category: PassCategory,
                trust: TrustLevel, status: PassStatus = .active, validity: PassValidity = PassValidity(),
                color: PassColor = .ink, identifier: String? = nil, fields: [PassField] = [],
                codePayload: String? = nil, createdAt: Date, updatedAt: Date) {
        self.id = id; self.title = title; self.issuer = issuer; self.category = category
        self.trust = trust; self.status = status; self.validity = validity; self.color = color
        self.identifier = identifier; self.fields = fields; self.codePayload = codePayload
        self.createdAt = createdAt; self.updatedAt = updatedAt
    }

    /// Only the last four letters/digits are shown, e.g. "•••• 4242".
    public var maskedIdentifier: String? {
        guard let identifier else { return nil }
        let significant = identifier.filter { $0.isLetter || $0.isNumber }
        guard significant.count > 4 else { return "••••" }
        return "•••• " + String(significant.suffix(4))
    }

    /// Samples and user-created passes can be edited. Imported, verified and
    /// payment passes carry external meaning and are read-only in the app.
    public var isEditable: Bool { trust == .sample || trust == .custom }
}
