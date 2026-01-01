import Foundation
import AppKit

class ArtGenerator {
    private let anthropicService = AnthropicService()
    private let pythonExecutor = PythonExecutor()

    private var outputDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("GeometricArtGenerator")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        return appDir
    }

    func generateArt(prompt: String, apiKey: String) async throws -> GeneratedArtResult {
        // Step 1: Generate Python code using Claude
        let pythonCode = try await anthropicService.generateCode(prompt: prompt, apiKey: apiKey)

        // Step 2: Execute Python code to create SVG
        let svgURL = try await pythonExecutor.execute(code: pythonCode, outputDir: outputDirectory)

        // Create result
        return GeneratedArtResult(
            prompt: prompt,
            pythonCode: pythonCode,
            svgPath: svgURL.path
        )
    }

    func exportToJPEG(svgPath: String, outputPath: URL) throws {
        try exportToImage(svgPath: svgPath, outputPath: outputPath, format: .jpeg)
    }

    func exportToPNG(svgPath: String, outputPath: URL) throws {
        try exportToImage(svgPath: svgPath, outputPath: outputPath, format: .png)
    }

    private func exportToImage(svgPath: String, outputPath: URL, format: NSBitmapImageRep.FileType) throws {
        guard let svgData = try? Data(contentsOf: URL(fileURLWithPath: svgPath)) else {
            throw ExportError.cannotReadSVG
        }

        guard let svgImage = NSImage(data: svgData) else {
            throw ExportError.cannotCreateImage
        }

        // Use high resolution for better quality (3x scale)
        let scale: CGFloat = 3.0
        let size = svgImage.size
        let scaledWidth = Int(size.width * scale)
        let scaledHeight = Int(size.height * scale)

        print("📸 Exporting at \(scaledWidth)x\(scaledHeight) (\(scale)x scale)")

        // Create a high-resolution bitmap representation
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: scaledWidth,
            pixelsHigh: scaledHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let rep = bitmapRep else {
            throw ExportError.cannotCreateBitmap
        }

        // Draw the image at high resolution
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        // Use high quality interpolation
        context?.imageInterpolation = .high

        // Draw scaled up
        svgImage.draw(
            in: NSRect(x: 0, y: 0, width: CGFloat(scaledWidth), height: CGFloat(scaledHeight)),
            from: NSRect.zero,
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()

        // Export with quality settings
        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]

        if format == .jpeg {
            // High quality JPEG (1.0 = maximum quality)
            properties[.compressionFactor] = 0.95
        }

        guard let data = rep.representation(using: format, properties: properties) else {
            throw ExportError.cannotConvert
        }

        try data.write(to: outputPath)
        print("✅ Exported \(format == .jpeg ? "JPEG" : "PNG") successfully")
    }
}

struct GeneratedArtResult {
    let prompt: String
    let pythonCode: String
    let svgPath: String
}

enum ExportError: LocalizedError {
    case cannotReadSVG
    case cannotCreateImage
    case cannotCreateBitmap
    case cannotConvert

    var errorDescription: String? {
        switch self {
        case .cannotReadSVG:
            return "Cannot read SVG file"
        case .cannotCreateImage:
            return "Cannot create image from SVG"
        case .cannotCreateBitmap:
            return "Cannot create bitmap representation"
        case .cannotConvert:
            return "Cannot convert to image format"
        }
    }
}
