import SwiftUI

struct PassCardView: View {
    let pass: WalletPass
    var now: Date = .now

    private var state: PassValidity.State { pass.validity.state(at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(pass.issuer.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                Spacer(minLength: Space.s)
                Image(systemName: pass.category.symbol).font(.title3).accessibilityHidden(true)
            }
            Spacer(minLength: Space.m)
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(pass.title).font(.title2.weight(.bold)).lineLimit(3)
                HStack(spacing: Space.s) {
                    if let masked = pass.maskedIdentifier {
                        Text(masked).font(.footnote.monospacedDigit())
                    }
                    Spacer(minLength: 0)
                    badge(pass.trust.label)
                    if let s = state.label { badge(s) }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(Space.m)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .background(Palette.card(pass.color), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(.white.opacity(0.12)))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func badge(_ text: String) -> some View {
        Text(text).font(.caption2.weight(.semibold))
            .padding(.horizontal, Space.s).padding(.vertical, 2)
            .background(.white.opacity(0.2), in: Capsule())
    }

    private var accessibilityText: String {
        var parts = [pass.title, pass.issuer.name, pass.category.plainTitle, pass.trust.label]
        if let s = state.label { parts.append(s) }
        if let m = pass.maskedIdentifier { parts.append(m) }
        return parts.joined(separator: ", ")
    }
}
