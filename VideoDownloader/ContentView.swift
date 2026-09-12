//
//  ContentView.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 11/09/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DownloaderViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                Text("YouTube Downloader")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Baixe vídeos ou áudios facilmente para o seu Mac")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)

            // Content
            GroupBox {
                VStack(spacing: 16) {
                    // URL
                    HStack {
                        Text("URL do Vídeo:")
                            .frame(width: 100, alignment: .trailing)
                        TextField("Cole o link do YouTube aqui...", text: $viewModel.url)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Formato
                    HStack {
                        Text("Formato:")
                            .frame(width: 100, alignment: .trailing)
                        Picker("", selection: $viewModel.selectedFormat) {
                            ForEach(DownloadFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Salvar em
                    HStack {
                        Text("Salvar em:")
                            .frame(width: 100, alignment: .trailing)
                        HStack(spacing: 8) {
                            TextField("", text: $viewModel.savePath)
                                .textFieldStyle(.roundedBorder)
                                .disabled(true)

                            Button("Escolher...") {
                                selectFolder()
                            }
                        }
                    }
                }
                .padding(16)
            }

            // Progress Section
            if viewModel.isDownloading || viewModel.progress > 0 {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.progress, total: 1.0)
                        .progressViewStyle(.linear)

                    HStack {
                        if viewModel.isDownloading {
                            ProgressView()
                                .controlSize(.small)
                        } else if !viewModel.hasError {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }

                        Text(viewModel.statusText)
                            .font(.callout)
                            .foregroundColor(viewModel.hasError ? .red : .secondary)
                    }
                }
            } else {
                // Placeholder para manter a altura consistente
                Spacer().frame(height: 38)
            }

            Spacer(minLength: 0)

            // Bottom Bar
            HStack {
                Text("⚠️ Requer **uv** e **ffmpeg**.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Baixar Agora") {
                    viewModel.startDownload()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isDownloading || viewModel.url.isEmpty)
            }
        }
        .padding(32)
        .frame(minWidth: 550, idealWidth: 550, minHeight: 450, idealHeight: 450)
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            if let url = panel.url {
                viewModel.savePath = url.path
            }
        }
    }
}

#Preview {
    ContentView()
}
