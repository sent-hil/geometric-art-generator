import SwiftUI

struct SettingsView: View {
    @AppStorage("anthropicAPIKey") private var apiKey: String = ""
    @State private var showAPIKeySaved = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Configure your Anthropic API settings")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.02, green: 0.02, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            ScrollView {
                VStack(spacing: 20) {
                    // API Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("API Configuration", systemImage: "key.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Anthropic API Key")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.7))

                            Text("Get your API key from console.anthropic.com")
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.5))

                            SecureField("sk-ant-...", text: $apiKey)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )

                            if showAPIKeySaved {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("API key saved successfully")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                    )

                    // Model Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Model Information", systemImage: "brain.head.profile")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Model")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(white: 0.7))
                                Spacer()
                                Text("claude-sonnet-4.5")
                                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 1.0))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.15))
                                    )
                            }

                            Divider()
                                .background(Color.white.opacity(0.1))

                            Text("Using the latest Anthropic Claude model for generating geometric art from text descriptions")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.5))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.02))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                    )
                }
                .padding(24)
            }
            .background(Color(red: 0.02, green: 0.02, blue: 0.05))

            // Save button
            HStack {
                Spacer()
                Button(action: saveAPIKey) {
                    Text("Save Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.5, blue: 1.0),
                                            Color(red: 0.3, green: 0.4, blue: 0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.3), radius: 8, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return)
            }
            .padding(20)
            .background(Color.black.opacity(0.3))
        }
        .frame(width: 600, height: 500)
    }

    private func saveAPIKey() {
        // Trim whitespace
        apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        // Debug: print actual string characters
        let keyPreview = String(apiKey.prefix(15))
        print("💾 Saving API key preview: '\(keyPreview)' (total length: \(apiKey.count))")
        print("💾 First char: '\(apiKey.first ?? Character(" "))'")

        // Force sync to disk
        UserDefaults.standard.synchronize()
        print("💾 UserDefaults synchronized to disk")

        // Verify it was saved
        let saved = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
        print("💾 Verification - saved key length: \(saved.count)")

        withAnimation(.spring(response: 0.3)) {
            showAPIKeySaved = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3)) {
                showAPIKeySaved = false
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
