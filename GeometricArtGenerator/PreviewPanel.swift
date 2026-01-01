import SwiftUI
import WebKit

struct PreviewPanel: View {
    @EnvironmentObject var appState: AppState
    private let artGenerator = ArtGenerator()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with glass morphism
            HStack(spacing: 16) {
                Label("Preview", systemImage: "paintpalette")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Export buttons
                HStack(spacing: 8) {
                    ExportButton(
                        icon: "square.and.arrow.up",
                        label: "SVG",
                        action: exportSVG,
                        disabled: appState.currentArt == nil
                    )

                    ExportButton(
                        icon: "photo",
                        label: "JPEG",
                        action: exportJPEG,
                        disabled: appState.currentArt == nil
                    )

                    ExportButton(
                        icon: "photo.fill",
                        label: "PNG",
                        action: exportPNG,
                        disabled: appState.currentArt == nil
                    )
                }
            }
            .padding(16)
            .background(
                ZStack {
                    Color.black.opacity(0.4)
                    Color.white.opacity(0.02)
                }
                .background(.ultraThinMaterial.opacity(0.5))
            )

            // SVG Preview Area
            if let art = appState.currentArt {
                SVGPreviewView(svgPath: art.svgPath)
                    .background(Color.black)
            } else {
                // Empty state with modern design
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.2),
                                        Color(red: 0.3, green: 0.4, blue: 0.9).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 30)

                        Image(systemName: "sparkles")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.6, green: 0.7, blue: 1.0),
                                        Color(red: 0.4, green: 0.5, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 8) {
                        Text("No art generated yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Enter a prompt and click Generate\nto create geometric art")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        Color(red: 0.02, green: 0.02, blue: 0.05)

                        // Subtle grid pattern
                        Canvas { context, size in
                            let spacing: CGFloat = 40
                            context.stroke(
                                Path { path in
                                    for x in stride(from: 0, through: size.width, by: spacing) {
                                        path.move(to: CGPoint(x: x, y: 0))
                                        path.addLine(to: CGPoint(x: x, y: size.height))
                                    }
                                    for y in stride(from: 0, through: size.height, by: spacing) {
                                        path.move(to: CGPoint(x: 0, y: y))
                                        path.addLine(to: CGPoint(x: size.width, y: y))
                                    }
                                },
                                with: .color(Color.white.opacity(0.02)),
                                lineWidth: 1
                            )
                        }
                    }
                )
            }
        }
    }

    private func exportSVG() {
        guard let art = appState.currentArt else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        saveFile(from: art.svgPath, defaultName: "geometric-art-\(timestamp).svg")
    }

    private func exportJPEG() {
        guard let art = appState.currentArt else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        exportImage(from: art.svgPath, defaultName: "geometric-art-\(timestamp).jpg", format: .jpeg)
    }

    private func exportPNG() {
        guard let art = appState.currentArt else { return }
        let timestamp = Int(Date().timeIntervalSince1970)
        exportImage(from: art.svgPath, defaultName: "geometric-art-\(timestamp).png", format: .png)
    }

    private func exportImage(from sourcePath: String, defaultName: String, format: NSBitmapImageRep.FileType) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = defaultName
        savePanel.allowedContentTypes = format == .jpeg ? [.jpeg] : [.png]

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    if format == .jpeg {
                        try artGenerator.exportToJPEG(svgPath: sourcePath, outputPath: url)
                    } else {
                        try artGenerator.exportToPNG(svgPath: sourcePath, outputPath: url)
                    }
                } catch {
                    print("Error exporting file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveFile(from sourcePath: String, defaultName: String) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = defaultName
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try FileManager.default.copyItem(atPath: sourcePath, toPath: url.path)
                } catch {
                    print("Error saving file: \(error)")
                }
            }
        }
    }
}

// MARK: - Export Button Component
struct ExportButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    let disabled: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(disabled ? Color.white.opacity(0.05) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(disabled ? 0.03 : 0.1), lineWidth: 1)
                    )
            )
            .foregroundColor(disabled ? Color(white: 0.4) : .white)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

// MARK: - SVG Preview using WebKit
struct SVGPreviewView: NSViewRepresentable {
    let svgPath: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let url = URL(fileURLWithPath: svgPath)

        // Add a cache-busting query parameter to force reload
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "t", value: "\(Date().timeIntervalSince1970)")]

        let loadURL = components?.url ?? url

        print("🖼️ Loading SVG: \(svgPath)")
        webView.loadFileURL(loadURL, allowingReadAccessTo: url.deletingLastPathComponent())
    }
}
