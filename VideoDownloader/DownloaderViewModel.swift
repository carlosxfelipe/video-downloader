//
//  DownloaderViewModel.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 12/09/26.
//

import Combine
import Foundation

enum DownloadFormat: String, CaseIterable, Identifiable {
    case mp4_4k = "Vídeo MP4 (4K / Melhor Qualidade)"
    case mp4_1080p = "Vídeo MP4 (1080p)"
    case mp4_720p = "Vídeo MP4 (720p)"
    case mp4_wallpaper = "Vídeo MP4 (Live Wallpaper macOS - H.264)"
    case audio_mp3 = "Apenas Áudio (MP3)"

    var id: String { rawValue }

    var ytdlpArgs: [String] {
        switch self {
        case .mp4_4k:
            return ["-f", "bestvideo[res<=2160]+bestaudio/best", "--merge-output-format", "mp4"]
        case .mp4_1080p:
            return ["-f", "bestvideo[res<=1080]+bestaudio/best", "--merge-output-format", "mp4"]
        case .mp4_720p:
            return ["-f", "bestvideo[res<=720]+bestaudio/best", "--merge-output-format", "mp4"]
        case .mp4_wallpaper:
            return ["-f", "bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/best[ext=mp4]", "--merge-output-format", "mp4"]
        case .audio_mp3:
            return ["-f", "bestaudio/best", "-x", "--audio-format", "mp3", "--audio-quality", "192K"]
        }
    }
}

extension String {
    var shellEscaped: String {
        return "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

class DownloaderViewModel: ObservableObject {
    @Published var url: String = ""
    @Published var selectedFormat: DownloadFormat = .mp4_1080p
    @Published var savePath: String = ""

    @Published var isDownloading: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusText: String = ""
    @Published var hasError: Bool = false

    private var process: Process?

    init() {
        if let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            savePath = downloadsDir.path
        }
    }

    func startDownload() {
        guard !url.isEmpty else {
            statusText = "Por favor, insira uma URL válida."
            hasError = true
            return
        }

        isDownloading = true
        hasError = false
        progress = 0.0
        statusText = "Iniciando download..."

        DispatchQueue.global(qos: .userInitiated).async {
            self.runYtDlp()
        }
    }

    private func runYtDlp() {
        let process = Process()
        self.process = process

        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        var args = ["uvx", "yt-dlp", "--newline", "--no-check-certificate"]
        args.append(contentsOf: selectedFormat.ytdlpArgs)

        let outTemplate = "\(savePath)/%(title)s.%(ext)s"
        args.append("-o")
        args.append(outTemplate)
        args.append(url)

        let command = args.map { $0.shellEscaped }.joined(separator: " ")
        process.arguments = ["-lc", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let str = String(data: data, encoding: .utf8) {
                self?.parseOutput(str)
            }
        }

        do {
            try process.run()
            process.waitUntilExit()

            DispatchQueue.main.async {
                self.isDownloading = false
                if process.terminationStatus == 0 {
                    self.progress = 1.0
                    self.statusText = "Download concluído com sucesso!"
                } else {
                    self.hasError = true
                    self.statusText = "Erro durante o download."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.hasError = true
                self.statusText = "Falha ao iniciar o processo: \(error.localizedDescription)"
            }
        }
    }

    private func parseOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("[download]"), line.contains("%") {
                DispatchQueue.main.async {
                    let text = line.replacingOccurrences(of: "[download]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    self.statusText = text

                    if let percentRange = text.range(of: #"\d+\.\d+%"#, options: .regularExpression) {
                        let percentStr = String(text[percentRange]).replacingOccurrences(of: "%", with: "")
                        if let percentFloat = Double(percentStr) {
                            self.progress = percentFloat / 100.0
                        }
                    }
                }
            }
        }
    }
}
