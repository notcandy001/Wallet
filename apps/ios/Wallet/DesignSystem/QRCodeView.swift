import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let payload: String

    var body: some View {
        VStack(spacing: Space.s) {
            if let image = Self.render(payload) {
                Image(uiImage: image)
                    .interpolation(.none).resizable().scaledToFit()
                    .frame(maxWidth: 240).padding(Space.m)
                    .background(.white, in: RoundedRectangle(cornerRadius: Radius.control))
                    .accessibilityLabel("QR code")
                    .accessibilityValue(payload)
            }
            // Visible text alternative to the code.
            Text(payload).font(.caption.monospaced()).foregroundStyle(.secondary)
                .textSelection(.enabled).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    static func render(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
