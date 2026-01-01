import SwiftUI

@main
struct GeometricArtGeneratorApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("anthropicAPIKey") private var apiKey: String = ""

    init() {
        // Debug: Check if API key persists
        let key = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
        print("🔐 App Launch - API key loaded: \(key.isEmpty ? "EMPTY" : "Found (\(key.count) chars)")")
        if !key.isEmpty {
            print("🔐 Key preview: \(String(key.prefix(15)))")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var currentPrompt = ""
    @Published var promptHistory: [String] = []
    @Published var generationHistory: [GeneratedArt] = []
    @Published var currentArt: GeneratedArt?
    @Published var isGenerating = false
    @Published var errorMessage: String?

    // Visual parameters
    @Published var lineThickness: Double = 1.0
    @Published var opacity: Double = 1.0
    @Published var backgroundColor: Color = .black

    private let artGenerator = ArtGenerator()

    func generateArt(apiKey: String) async {
        guard !currentPrompt.isEmpty else { return }

        await MainActor.run {
            isGenerating = true
            errorMessage = nil
            addPromptToHistory(currentPrompt)
        }

        do {
            let result = try await artGenerator.generateArt(prompt: currentPrompt, apiKey: apiKey)

            let art = GeneratedArt(
                prompt: result.prompt,
                pythonCode: result.pythonCode,
                svgPath: result.svgPath,
                timestamp: Date()
            )

            await MainActor.run {
                addToHistory(art: art)
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }

    func addToHistory(art: GeneratedArt) {
        generationHistory.insert(art, at: 0)
        currentArt = art
    }

    func addPromptToHistory(_ prompt: String) {
        if !promptHistory.contains(prompt) {
            promptHistory.insert(prompt, at: 0)
            if promptHistory.count > 20 {
                promptHistory.removeLast()
            }
        }
    }
}

// MARK: - Models
struct GeneratedArt: Identifiable {
    let id = UUID()
    let prompt: String
    let pythonCode: String
    let svgPath: String
    let timestamp: Date

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "\(prompt.prefix(30)) - \(formatter.string(from: timestamp))"
    }
}
