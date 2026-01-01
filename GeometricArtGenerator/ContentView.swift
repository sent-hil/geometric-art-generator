import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HSplitView {
            // Left Panel - Input and Controls
            InputPanel()
                .frame(minWidth: 400, maxWidth: 500)

            // Right Panel - SVG Preview
            PreviewPanel()
                .frame(minWidth: 600)
        }
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .frame(width: 1200, height: 800)
    }
}
