import SwiftUI

struct InputPanel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderSection()
                PromptInputSection()
                HistorySection()
                Spacer()
            }
            .padding(24)
        }
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Header Section
private struct HeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Geometric Art")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(headerGradient)

            Text("AI-powered generative design")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(white: 0.5))
        }
        .padding(.top, 8)
    }

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [.white, Color(white: 0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Prompt Input Section
private struct PromptInputSection: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("anthropicAPIKey") private var apiKey: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PromptHeader()

            // Example prompts if text is empty
            if appState.currentPrompt.isEmpty {
                ExamplePromptsView()
            }

            PromptTextEditor()
            GenerateButton(action: generateArt)

            // Error message display
            if let errorMessage = appState.errorMessage {
                ErrorMessageView(message: errorMessage)
            }
        }
    }

    private func generateArt() {
        let keyPreview = String(apiKey.prefix(15))
        print("🎨 Generate - API key preview: '\(keyPreview)' (length: \(apiKey.count))")

        Task {
            await appState.generateArt(apiKey: apiKey)
        }
    }
}

// MARK: - Example Prompts
private struct ExamplePromptsView: View {
    @EnvironmentObject var appState: AppState

    let examples = [
        "circles",
        "spirals",
        "triangles",
        "hexagons",
        "waves",
        "mandala"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try these:")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(white: 0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 6) {
                ForEach(examples, id: \.self) { example in
                    Button(action: {
                        withAnimation(.spring(response: 0.2)) {
                            appState.currentPrompt = example
                        }
                    }) {
                        Text(example)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(white: 0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ErrorMessageView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
            }

            // Selectable text for error message
            TextEditor(text: .constant(message))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.red.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(height: 60)
                .padding(8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct PromptHeader: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Label("Prompt", systemImage: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(white: 0.9))

            Spacer()

            if !appState.promptHistory.isEmpty {
                PromptHistoryMenu()
            }
        }
    }
}

private struct PromptHistoryMenu: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Menu {
            ForEach(appState.promptHistory, id: \.self) { prompt in
                Button(prompt) {
                    appState.currentPrompt = prompt
                }
            }
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(white: 0.6))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.05))
                )
        }
        .menuStyle(.borderlessButton)
    }
}

private struct PromptTextEditor: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TextEditor(text: $appState.currentPrompt)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(textEditorBackground)
            .frame(height: 120)
    }

    private var textEditorBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
}

private struct GenerateButton: View {
    @EnvironmentObject var appState: AppState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                buttonIcon
                buttonText
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(buttonBackground)
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(appState.currentPrompt.isEmpty || appState.isGenerating)
    }

    @ViewBuilder
    private var buttonIcon: some View {
        if appState.isGenerating {
            ProgressView()
                .scaleEffect(0.7)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        } else {
            Image(systemName: "wand.and.stars.inverse")
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var buttonText: some View {
        Text(appState.isGenerating ? "Generating..." : "Generate Art")
            .font(.system(size: 14, weight: .semibold))
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if appState.currentPrompt.isEmpty || appState.isGenerating {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(activeGradient)
                .shadow(color: Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.3), radius: 12, y: 6)
        }
    }

    private var activeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.5, blue: 1.0),
                Color(red: 0.3, green: 0.4, blue: 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Parameters Section
private struct ParametersSection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Parameters", systemImage: "slider.horizontal.3")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(white: 0.9))

            VStack(spacing: 16) {
                ParameterSlider(
                    title: "Line Thickness",
                    value: $appState.lineThickness,
                    range: 0.1...5.0,
                    format: "%.1f"
                )

                ParameterSlider(
                    title: "Opacity",
                    value: $appState.opacity,
                    range: 0.1...1.0,
                    format: "%.0f%%",
                    multiplier: 100
                )

                BackgroundColorPicker()
            }
            .padding(16)
            .background(parametersBackground)
        }
    }

    private var parametersBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

private struct BackgroundColorPicker: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(white: 0.7))

            HStack(spacing: 10) {
                ColorCircle(color: .black)
                ColorCircle(color: Color(white: 0.08))
                ColorCircle(color: Color(white: 0.15))
            }
        }
    }
}

private struct ColorCircle: View {
    @EnvironmentObject var appState: AppState
    let color: Color

    private var isSelected: Bool {
        appState.backgroundColor == color
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 36, height: 36)
            .overlay(circleOverlay)
            .shadow(color: isSelected ? Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.4) : .clear, radius: 6)
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    appState.backgroundColor = color
                }
            }
    }

    private var circleOverlay: some View {
        Circle()
            .strokeBorder(
                isSelected ? Color(red: 0.4, green: 0.5, blue: 1.0) : Color.white.opacity(0.15),
                lineWidth: isSelected ? 2.5 : 1
            )
    }
}

// MARK: - Parameter Slider Component
struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    var multiplier: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(white: 0.7))
                Spacer()
                valueBadge
            }

            Slider(value: $value, in: range)
                .tint(sliderGradient)
        }
    }

    private var valueBadge: some View {
        Text(String(format: format, value * multiplier))
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 1.0))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.15))
            )
    }

    private var sliderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.5, blue: 1.0),
                Color(red: 0.5, green: 0.4, blue: 0.9)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - History Section
private struct HistorySection: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("History", systemImage: "clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(white: 0.9))

            if appState.generationHistory.isEmpty {
                EmptyHistoryView()
            } else {
                HistoryList()
            }
        }
    }
}

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundColor(Color(white: 0.3))
            Text("No generations yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct HistoryList: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(appState.generationHistory) { art in
                    HistoryItemView(art: art)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                appState.currentArt = art
                            }
                        }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}

// MARK: - History Item View
struct HistoryItemView: View {
    let art: GeneratedArt
    @EnvironmentObject var appState: AppState

    private var isSelected: Bool {
        appState.currentArt?.id == art.id
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(art.prompt)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(art.timestamp, style: .relative)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()

            if isSelected {
                selectionIndicator
            }
        }
        .padding(12)
        .background(itemBackground)
    }

    private var thumbnailView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(thumbnailGradient)
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(white: 0.3))
            )
    }

    private var thumbnailGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(white: 0.15),
                Color(white: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var selectionIndicator: some View {
        Circle()
            .fill(Color(red: 0.4, green: 0.5, blue: 1.0))
            .frame(width: 6, height: 6)
    }

    private var itemBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.12) : Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color(red: 0.4, green: 0.5, blue: 1.0).opacity(0.3) : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
    }
}
