import Foundation

/// Explicitly fictional passes. Fixed IDs so the set is stable across launches.
public enum SampleData {
    public static func passes(now: Date) -> [WalletPass] {
        let day: TimeInterval = 86_400
        func id(_ n: Int) -> UUID { UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))! }
        func make(_ n: Int, _ title: String, _ issuer: String, _ cat: PassCategory, _ color: PassColor,
                  identifier: String? = nil, fields: [PassField] = [], code: String? = nil,
                  from: Date? = nil, until: Date? = nil, age: Double) -> WalletPass {
            WalletPass(id: id(n), title: title, issuer: PassIssuer(name: issuer), category: cat, trust: .sample,
                       validity: PassValidity(validFrom: from, expiresAt: until), color: color, identifier: identifier,
                       fields: fields, codePayload: code, createdAt: now.addingTimeInterval(-age * day), updatedAt: now)
        }
        return [
            make(1, "Rewards", "Bean & Leaf Café", .loyalty, .forest, identifier: "BL-0042-7781",
                 fields: [PassField(label: "Points", value: "240"), PassField(label: "Tier", value: "Silver")],
                 code: "SAMPLE-LOYALTY-BL-0042-7781", age: 6),
            make(2, "Annual Membership", "Lakeview Fitness", .membership, .indigo, identifier: "LF-9913-2044",
                 fields: [PassField(label: "Branch", value: "Indiranagar")], code: "SAMPLE-MEMBER-LF-9913-2044",
                 until: now.addingTimeInterval(20 * day), age: 5),
            make(3, "Indie Night Live", "Sample Events Co.", .eventTicket, .plum, identifier: "EV-5521-0009",
                 fields: [PassField(label: "Gate", value: "B"), PassField(label: "Seat", value: "Standing")],
                 code: "SAMPLE-TICKET-EV-5521-0009", from: now.addingTimeInterval(3 * day), until: now.addingTimeInterval(4 * day), age: 4),
            make(4, "SA 101 · BLR → DEL", "Sample Air", .boardingPass, .teal, identifier: "SA101-PNR4XQ",
                 fields: [PassField(label: "Gate", value: "12"), PassField(label: "Seat", value: "14C"), PassField(label: "Boards", value: "06:40")],
                 code: "SAMPLE-BOARDING-SA101-PNR4XQ", until: now.addingTimeInterval(2 * day), age: 3),
            make(5, "Day Pass", "Commons Co-working", .general, .amber, identifier: "CC-DAY-1180",
                 until: now.addingTimeInterval(-2 * day), age: 2),
            make(6, "Library Reference", "Sample City Library", .documentReference, .slate, identifier: "LIB-22-8830",
                 fields: [PassField(label: "Note", value: "Reference only — not an official ID")], age: 1),
            make(7, "Demo Card", "Sample Bank (demo)", .paymentCardRepresentation, .ink, identifier: "DEMO-4242",
                 fields: [PassField(label: "Note", value: "Visual only — cannot make payments")], age: 0.5),
        ]
    }
}
