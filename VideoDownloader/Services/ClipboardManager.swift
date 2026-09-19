//
//  ClipboardManager.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 18/09/26.
//

import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class ClipboardManager {
    static let shared = ClipboardManager()

    /// ── State ────────────────────────────────────────────────────────────────
    private(set) var history: [String] = []

    // ── Private ──────────────────────────────────────────────────────────────
    private let maxItems = 8
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?

    private init() {
        startMonitoring()
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /// Re-coloca o item no clipboard do sistema e move-o para o topo do histórico.
    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        // Update changeCount so next poll doesn't add a duplicate
        lastChangeCount = NSPasteboard.general.changeCount
        // Move to top
        history.removeAll { $0 == text }
        history.insert(text, at: 0)
    }

    /// Limpa o histórico interno (não afeta o clipboard do sistema).
    func clear() {
        history.removeAll()
    }

    // ── Monitoring ───────────────────────────────────────────────────────────

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkClipboard()
            }
        }
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.hasPrefix("https://")
        else { return }

        // Evita duplicata consecutiva no topo
        if history.first == text {
            return
        }

        history.removeAll { $0 == text }
        history.insert(text, at: 0)

        if history.count > maxItems {
            history.removeLast()
        }
    }
}
