// PORTED FROM: New file — BionicSX2 iOS Port
// AUDIT REFERENCE: Section 4.3 (SwiftUI app entry point),
//                  Section 13.3 (ios/ui/BionicSX2App.swift)
// STATUS: NEW — SwiftUI @main entry point

import SwiftUI

@main
struct BionicSX2App: App {
    @State private var showGameList = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Configure AVAudioSession for low-latency audio playback
                    // Audit Section 9.3
                    configureAudio()
                }
        }
    }

    private func configureAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005) // 5ms latency per audit Sec 9.3
            try session.setActive(true)
        } catch {
            NSLog("[BionicSX2] Audio session config failed: \(error.localizedDescription)")
        }
    }
}
