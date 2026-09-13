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

    /// Com recorte ativo, tenta a resolução escolhida e, se o stream não existir,
    /// cai para o melhor disponível (evita "Requested format is not available").
    var cropFormatSelector: String {
        switch self {
        case .mp4_4k: return "bestvideo[res<=2160]+bestaudio/bestvideo+bestaudio/best"
        case .mp4_1080p: return "bestvideo[res<=1080]+bestaudio/bestvideo+bestaudio/best"
        case .mp4_720p: return "bestvideo[res<=720]+bestaudio/bestvideo+bestaudio/best"
        case .mp4_wallpaper: return "bestvideo[vcodec^=avc1]+bestaudio/bestvideo+bestaudio/best"
        case .audio_mp3: return "bestaudio/best"
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
    @Published var startTime: String = ""
    @Published var endTime: String = ""

    @Published var isDownloading: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusText: String = ""
    @Published var hasError: Bool = false

    var isCropValid: Bool {
        let hasCrop = !startTime.isEmpty || !endTime.isEmpty
        guard hasCrop else { return true }

        // Se só tem inicio e fim vazio, é até o final (válido)
        if endTime.isEmpty { return true }

        let startStr = startTime.isEmpty ? "00:00:00" : startTime
        let startSecs = timeToSeconds(startStr)
        let endSecs = timeToSeconds(endTime)

        return startSecs < endSecs
    }

    private func timeToSeconds(_ time: String) -> Int {
        let parts = time.components(separatedBy: ":")
        guard parts.count == 3,
              let h = Int(parts[0]),
              let m = Int(parts[1]),
              let s = Int(parts[2])
        else {
            return 0
        }
        return (h * 3600) + (m * 60) + s
    }

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

        guard isCropValid else {
            statusText = "O tempo 'Até' deve ser maior que o tempo 'De'."
            hasError = true
            return
        }

        isDownloading = true
        hasError = false
        progress = 0.0
        statusText = "Iniciando download..."

        // Captura na main thread antes de entrar no background
        let capturedURL = url
        let capturedFormat = selectedFormat
        let capturedSavePath = savePath
        let capturedStart = startTime
        let capturedEnd = endTime

        DispatchQueue.global(qos: .userInitiated).async {
            self.runYtDlp(
                url: capturedURL,
                format: capturedFormat,
                savePath: capturedSavePath,
                startTime: capturedStart,
                endTime: capturedEnd
            )
        }
    }

    private func runYtDlp(
        url: String,
        format: DownloadFormat,
        savePath: String,
        startTime: String,
        endTime: String
    ) {
        let process = Process()
        self.process = process
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        var args = ["uvx", "yt-dlp", "--newline", "--no-check-certificate"]
        args.append(contentsOf: format.ytdlpArgs)

        if !startTime.isEmpty || !endTime.isEmpty {
            let start = startTime.isEmpty ? "00:00:00" : startTime
            let end = endTime.isEmpty ? "inf" : endTime
            args.append("--download-sections")
            args.append("*\(start)-\(end)")
            // Substitui o seletor de formato pelo cropFormatSelector que tem fallback robusto
            if let fIdx = args.firstIndex(of: "-f") {
                args[fIdx + 1] = format.cropFormatSelector
            }
            if format != .audio_mp3, !args.contains("--merge-output-format") {
                args.append("--merge-output-format")
                args.append("mp4")
            }
        }

        // Nomes distintos para recorte e download completo — evita sobrescrever um com o outro.
        // Parênteses são seguros em templates yt-dlp; colchetes [] são reservados para expressões condicionais.
        let hasCrop = !startTime.isEmpty || !endTime.isEmpty
        let outTemplate: String
        if hasCrop {
            let s = (startTime.isEmpty ? "00:00:00" : startTime).replacingOccurrences(of: ":", with: "-")
            let e = (endTime.isEmpty ? "end" : endTime).replacingOccurrences(of: ":", with: "-")
            outTemplate = "\(savePath)/%(title)s (\(s) to \(e)).%(ext)s"
        } else {
            outTemplate = "\(savePath)/%(title)s.%(ext)s"
        }
        args.append("--force-overwrites")
        args.append("-o")
        args.append(outTemplate)
        args.append(url)

        let command = args.map { $0.shellEscaped }.joined(separator: " ")
        process.arguments = ["-lc", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        var collectedOutput = ""
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let str = String(data: data, encoding: .utf8) {
                collectedOutput += str
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
                    let lastLines = collectedOutput
                        .components(separatedBy: .newlines)
                        .filter { !$0.isEmpty }
                        .suffix(3)
                        .joined(separator: " | ")
                    self.statusText = lastLines.isEmpty ? "Erro durante o download." : lastLines
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
