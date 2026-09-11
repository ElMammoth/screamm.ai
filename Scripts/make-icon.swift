import SwiftUI
import AppKit

/// The app icon: a brand-orange macOS squircle with the waveform mark from the dictation pill.
/// Deliberately simple — it has to stay readable at 16pt in the Finder sidebar.
struct AppIcon: View {
    // Apple's macOS grid: the art sits in ~824pt of a 1024pt canvas.
    var body: some View {
        let side: CGFloat = 1024
        let inset: CGFloat = 100
        let box = side - inset * 2

        ZStack {
            RoundedRectangle(cornerRadius: box * 0.2237, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.980, green: 0.639, blue: 0.106),
                             Color(red: 0.886, green: 0.451, blue: 0.008)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: box, height: box)
                .shadow(color: .black.opacity(0.22), radius: 26, y: 14)

            // Waveform: symmetric, tallest in the middle, same mark as the pill.
            HStack(spacing: box * 0.042) {
                ForEach(Array([0.38, 0.72, 1.0, 0.72, 0.38].enumerated()), id: \.offset) { _, h in
                    Capsule().fill(.white)
                        .frame(width: box * 0.062, height: box * 0.46 * h)
                }
            }
        }
        .frame(width: side, height: side)
    }
}

@main @MainActor enum Main {
    static func main() {
        let r = ImageRenderer(content: AppIcon())
        r.scale = 1
        guard let img = r.cgImage else { print("no image"); exit(1) }
        let data = NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!
        try! data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
        print("ok")
    }
}
