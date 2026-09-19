//
//  VideoDownloaderApp.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 11/09/26.
//

import AppKit
import SwiftUI

// ── App Delegate ─────────────────────────────────────────────────────────────

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_: Notification) {
        // Oculta o app do Dock — aparece apenas na menu bar
        NSApp.setActivationPolicy(.accessory)
    }
}

// ── App ───────────────────────────────────────────────────────────────────────

@main
struct VideoDownloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var clipboardManager = ClipboardManager.shared

    var body: some Scene {
        // ── Main window ───────────────────────────────────────────────────────
        Window("Video Downloader", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                AboutMenuButton()
            }
        }

        // ── About window ──────────────────────────────────────────────────────
        Window("Sobre", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .restorationBehavior(.disabled)

        // ── Menu bar extra ────────────────────────────────────────────────────
        MenuBarExtra("Video Downloader", systemImage: "arrow.down.circle.fill") {
            ClipboardMenuContent(manager: clipboardManager)
        }
        .menuBarExtraStyle(.menu)
    }
}

// ── Menu bar clipboard content ─────────────────────────────────────────────

private struct ClipboardMenuContent: View {
    let manager: ClipboardManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // ── Histórico de clipboard ────────────────────────────────────────────
        if manager.history.isEmpty {
            Label("Nenhum item copiado", systemImage: "tray")
                .foregroundStyle(.secondary)
        } else {
            ForEach(manager.history, id: \.self) { item in
                Button(action: { manager.copy(item) }) {
                    Text(truncated(item))
                }
            }

            Divider()

            Button(role: .destructive, action: { manager.clear() }) {
                Label("Limpar Histórico", systemImage: "trash")
            }
        }

        Divider()

        // ── Ações do app ──────────────────────────────────────────────────────
        Button(action: {
            openWindow(id: "about")
            NSApp.activate(ignoringOtherApps: true)
        }) {
            Label("Sobre", systemImage: "info.circle")
        }

        Button(action: {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }) {
            Label("Abrir Painel", systemImage: "macwindow")
        }

        Divider()

        Button(action: { NSApplication.shared.terminate(nil) }) {
            Label("Sair", systemImage: "power")
        }
    }

    /// Exibe início (domínio) + fim (ID do vídeo) para URLs longas
    private func truncated(_ url: String, maxLength: Int = 60) -> String {
        guard url.count > maxLength else { return url }
        let head = 35
        let tail = maxLength - head - 1 // 1 para o "…"
        return String(url.prefix(head)) + "…" + String(url.suffix(tail))
    }
}

// ── Helpers to access openWindow inside a Commands context ────────────────

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
