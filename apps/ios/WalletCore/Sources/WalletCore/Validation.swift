import Foundation

public enum DraftField: String, Sendable { case title, issuer, identifier, validity, fields, codePayload }

public struct ValidationError: Error, Hashable, Sendable {
    public enum Code: String, Sendable { case required, tooLong, invalidCharacters, invalidRange, tooMany }
    public let field: DraftField
    public let code: Code
    public init(field: DraftField, code: Code) { self.field = field; self.code = code }
}

public enum PassLimits {
    public static let title = 60
    public static let issuer = 60
    public static let identifier = 64
    public static let fieldLabel = 30
    public static let fieldValue = 120
    public static let maxFields = 8
    public static let codePayload = 300
    public static let importBytes = 1_000_000
}

/// User-editable form state. A draft can only ever produce a `.custom` pass
/// (or update an existing sample/custom one); it cannot claim verification.
public struct PassDraft: Equatable, Sendable {
    public var category: PassCategory
    public var title: String
    public var issuer: String
    public var identifier: String
    public var color: PassColor
    public var validFrom: Date?
    public var expiresAt: Date?
    public var fields: [PassField]
    public var codePayload: String

    public init(category: PassCategory = .general, title: String = "", issuer: String = "",
                identifier: String = "", color: PassColor = .ink, validFrom: Date? = nil,
                expiresAt: Date? = nil, fields: [PassField] = [], codePayload: String = "") {
        self.category = category; self.title = title; self.issuer = issuer
        self.identifier = identifier; self.color = color; self.validFrom = validFrom
        self.expiresAt = expiresAt; self.fields = fields; self.codePayload = codePayload
    }

    public init(from pass: WalletPass) {
        self.init(category: pass.category, title: pass.title, issuer: pass.issuer.name,
                  identifier: pass.identifier ?? "", color: pass.color,
                  validFrom: pass.validity.validFrom, expiresAt: pass.validity.expiresAt,
                  fields: pass.fields, codePayload: pass.codePayload ?? "")
    }

    public func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        func check(_ text: String, _ field: DraftField, max: Int, required: Bool, allowed: ((Unicode.Scalar) -> Bool)? = nil) {
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { if required { errors.append(.init(field: field, code: .required)) }; return }
            if t.count > max { errors.append(.init(field: field, code: .tooLong)); return }
            if t.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) || CharacterSet.newlines.contains($0) }) {
                errors.append(.init(field: field, code: .invalidCharacters)); return
            }
            if let allowed, !t.unicodeScalars.allSatisfy(allowed) { errors.append(.init(field: field, code: .invalidCharacters)) }
        }
        check(title, .title, max: PassLimits.title, required: true)
        check(issuer, .issuer, max: PassLimits.issuer, required: true)
        check(identifier, .identifier, max: PassLimits.identifier, required: false) { s in
            CharacterSet.alphanumerics.contains(s) || "-_./ ".unicodeScalars.contains(s)
        }
        check(codePayload, .codePayload, max: PassLimits.codePayload, required: false)

        if let from = validFrom, let end = expiresAt, end <= from {
            errors.append(.init(field: .validity, code: .invalidRange))
        }
        if fields.count > PassLimits.maxFields { errors.append(.init(field: .fields, code: .tooMany)) }
        for f in fields {
            let label = f.label.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = f.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if label.isEmpty || value.isEmpty { errors.append(.init(field: .fields, code: .required)); break }
            if label.count > PassLimits.fieldLabel || value.count > PassLimits.fieldValue { errors.append(.init(field: .fields, code: .tooLong)); break }
            let bad = (label + value).unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) || CharacterSet.newlines.contains($0) }
            if bad { errors.append(.init(field: .fields, code: .invalidCharacters)); break }
        }
        return errors
    }

    private func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Creates a new user-created pass. Throws the full list of validation errors.
    public func makePass(id: UUID = UUID(), now: Date) throws -> WalletPass {
        let errors = validate()
        guard errors.isEmpty else { throw ValidationErrors(errors: errors) }
        return WalletPass(id: id, title: trimmed(title), issuer: PassIssuer(name: trimmed(issuer)),
                          category: category, trust: .custom, validity: PassValidity(validFrom: validFrom, expiresAt: expiresAt),
                          color: color, identifier: trimmed(identifier).nilIfEmpty,
                          fields: fields.map { PassField(label: trimmed($0.label), value: trimmed($0.value)) },
                          codePayload: trimmed(codePayload).nilIfEmpty, createdAt: now, updatedAt: now)
    }

    /// Applies the draft to an existing editable pass, keeping id, trust, status and creation date.
    public func applying(to pass: WalletPass, now: Date) throws -> WalletPass {
        guard pass.isEditable else { throw ValidationErrors(errors: []) }
        var updated = try makePass(id: pass.id, now: now)
        updated.trust = pass.trust
        updated.status = pass.status
        updated.createdAt = pass.createdAt
        return updated
    }
}

public struct ValidationErrors: Error, Sendable { public let errors: [ValidationError] }

private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }
