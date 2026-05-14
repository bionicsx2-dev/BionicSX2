// PORTED FROM: New file — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 8.4 (touch input, game list browser),
//                  Section 2.6 (ISO file-based game loading only)
// STATUS: NEW

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var games: [String] = []
    @State private var showFilePicker = false
    @State private var showGameView = false

    var body: some View {
        NavigationStack {
            List(games, id: \.self) { game in
                Button(action: {
                    startGame(path: game)
                }) {
                    Text(URL(fileURLWithPath: game).lastPathComponent)
                }
            }
            .navigationTitle("BionicSX2")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Game") {
                        showFilePicker = true
                    }
                }
            }
            .onAppear {
                loadGames()
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    // Audit Section 2.6: iOS uses file-based game loading only
                    games.append(url.path)
                }
            }
            .fullScreenCover(isPresented: $showGameView) {
                MetalViewControllerRepresentable()
                    .ignoresSafeArea()
            }
        }
    }

    private func loadGames() {
        // Audit Section 2.6: ISO/CHD file reading is the ONLY path on iOS
        let documentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let gamesDir = documentsDir + "/Games"
        let fm = FileManager.default
        if fm.fileExists(atPath: gamesDir) {
            if let files = try? fm.contentsOfDirectory(atPath: gamesDir) {
                games = files
                    .filter { $0.hasSuffix(".iso") || $0.hasSuffix(".chd") || $0.hasSuffix(".cso") }
                    .map { gamesDir + "/" + $0 }
            }
        }
    }

    private func startGame(path: String) {
        showGameView = true
    }
}
