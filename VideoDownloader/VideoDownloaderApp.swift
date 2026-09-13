//
//  VideoDownloaderApp.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 11/09/26.
//

import SwiftUI

@main
struct VideoDownloaderApp: App {
    var body: some Scene {
        WindowGroup("Video Downloader") {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
            }
        }

        // ── About window ─────────────────────────────────────────────────────
        Window("Sobre o Video Downloader", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)
    }
}

// ── Helpers to access openWindow inside a Commands context ───────────

private struct AboutMenuButton: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(action: {
            openWindow(id: "about")
            NSApp.activate(ignoringOtherApps: true)
        }) {
            Label("Sobre VideoDownloader", systemImage: "info.circle")
        }
    }
}
