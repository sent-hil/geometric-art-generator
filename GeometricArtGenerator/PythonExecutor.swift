import Foundation

class PythonExecutor {
    func execute(code: String, outputDir: URL) async throws -> URL {
        // Create a temporary Python file
        let tempDir = FileManager.default.temporaryDirectory
        let pythonFile = tempDir.appendingPathComponent("generate_art_\(UUID().uuidString).py")

        // Use unique filename for each generation to avoid caching
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let uniqueFilename = "output_\(timestamp).svg"
        let outputSVGPath = outputDir.appendingPathComponent(uniqueFilename)

        print("🐍 Python file: \(pythonFile.path)")
        print("📄 Output SVG: \(outputSVGPath.path)")

        // Modify code to use the specific output path
        let modifiedCode = code.replacingOccurrences(
            of: "'output.svg'",
            with: "'\(outputSVGPath.path)'"
        ).replacingOccurrences(
            of: "\"output.svg\"",
            with: "\"\(outputSVGPath.path)\""
        )

        // Write Python code to file
        try modifiedCode.write(to: pythonFile, atomically: true, encoding: .utf8)

        // Execute Python - try different paths to find python3
        let process = Process()

        // Find python3 executable
        let pythonPaths = [
            "/usr/bin/python3",
            "/usr/local/bin/python3",
            "/opt/homebrew/bin/python3"
        ]

        var pythonPath: String?
        for path in pythonPaths {
            if FileManager.default.fileExists(atPath: path) {
                pythonPath = path
                print("✅ Found Python at: \(path)")
                break
            }
        }

        guard let validPythonPath = pythonPath else {
            throw PythonExecutorError.pythonNotFound
        }

        process.executableURL = URL(fileURLWithPath: validPythonPath)
        process.arguments = [pythonFile.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        print("🚀 Executing Python...")

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw PythonExecutorError.executionFailed(message: "Failed to launch Python: \(error.localizedDescription)")
        }

        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        if !output.isEmpty {
            print("📤 Python output: \(output)")
        }
        if !errorOutput.isEmpty {
            print("⚠️ Python stderr: \(errorOutput)")
        }

        // Clean up temp Python file
        try? FileManager.default.removeItem(at: pythonFile)

        // Check for errors
        if process.terminationStatus != 0 {
            throw PythonExecutorError.executionFailed(message: errorOutput.isEmpty ? "Unknown error (exit code: \(process.terminationStatus))" : errorOutput)
        }

        // Verify SVG was created
        guard FileManager.default.fileExists(atPath: outputSVGPath.path) else {
            throw PythonExecutorError.noOutputFile
        }

        print("✅ SVG created successfully")
        return outputSVGPath
    }
}

enum PythonExecutorError: LocalizedError {
    case pythonNotFound
    case executionFailed(message: String)
    case noOutputFile

    var errorDescription: String? {
        switch self {
        case .pythonNotFound:
            return "Python 3 not found. Please install Python 3 from python.org or use Homebrew: brew install python3"
        case .executionFailed(let message):
            return "Python execution failed: \(message)"
        case .noOutputFile:
            return "No output SVG file was generated"
        }
    }
}
