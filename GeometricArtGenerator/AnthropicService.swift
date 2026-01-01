import Foundation

class AnthropicService {
    private let apiURL = "https://api.anthropic.com/v1/messages"

    func generateCode(prompt: String, apiKey: String) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🔑 API Service - Key preview: '\(String(trimmedKey.prefix(15)))' (length: \(trimmedKey.count))")

        guard !trimmedKey.isEmpty else {
            throw AnthropicError.missingAPIKey
        }

        guard trimmedKey.hasPrefix("sk-ant-") else {
            throw AnthropicError.invalidAPIKey
        }

        let systemPrompt = """
        You are a geometric art generator. Create beautiful, minimalist geometric artwork using Python and SVG.

        STYLE GUIDELINES:
        - Clean, minimalist aesthetic with bold geometric shapes
        - Use mathematical patterns: spirals, fractals, tessellations, grids
        - Modern color palettes: gradients, complementary colors, monochrome with accent
        - Canvas size: 800x800px
        - Center compositions for visual balance
        - Create depth through layering and transparency

        INTERPRET SIMPLE INPUTS:
        If the user provides just shape names, expand them into artistic compositions:
        - "circles" → concentric circles with gradient, or overlapping circles in a pattern
        - "triangles" → geometric mountain range, or tessellated triangle grid
        - "squares" → rotating squares, or grid with varying sizes and colors
        - "spirals" → fibonacci spiral, or multiple spirals radiating from center
        - "lines" → radiating lines, parallel lines with varying thickness, or intersecting line art

        PYTHON CODE REQUIREMENTS:
        - Use ONLY Python standard library (no numpy, matplotlib, etc.)
        - Write raw SVG XML using string manipulation
        - Save to 'output.svg'
        - Include proper SVG header: <?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" width="800" height="800">
        - Use <circle>, <rect>, <line>, <polygon>, <path> elements
        - Add colors, gradients, and transparency for visual appeal
        - Code must be complete and executable

        EXAMPLE STRUCTURE:
        ```python
        def create_art():
            svg_content = '<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" width="800" height="800">'
            # Add geometric shapes here
            svg_content += '</svg>'
            with open('output.svg', 'w') as f:
                f.write(svg_content)

        create_art()
        ```

        Return ONLY executable Python code, no explanations or markdown.
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": "Create geometric art: \(prompt)"
                ]
            ]
        ]

        guard let url = URL(string: apiURL) else {
            throw AnthropicError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(trimmedKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        print("📡 Making request to: \(apiURL)")
        print("🔑 Headers: \(request.allHTTPHeaderFields ?? [:])")

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnthropicError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error (\(httpResponse.statusCode)): \(errorMessage)")
            throw AnthropicError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        print("✅ API request successful")

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let content = json?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AnthropicError.invalidResponse
        }

        return extractPythonCode(from: text)
    }

    private func extractPythonCode(from text: String) -> String {
        // Remove markdown code blocks if present
        var code = text

        // Remove ```python or ``` blocks
        if code.contains("```python") {
            code = code.replacingOccurrences(of: "```python", with: "")
        }
        if code.contains("```") {
            code = code.replacingOccurrences(of: "```", with: "")
        }

        return code.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AnthropicError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please add your Anthropic API key in Settings."
        case .invalidAPIKey:
            return "API key is invalid. It should start with 'sk-ant-'. Please check your API key in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}
