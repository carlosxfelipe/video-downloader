//
//  AboutView.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 12/09/26.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct AboutView: View {
    /// Read version and build number directly from the app bundle
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    private var versionLabel: String {
        build.isEmpty || build == version ? "Versão \(version)" : "Versão \(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── App Icon ─────────────────────────────────────────────────────
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .padding(.top, 28)

            // ── App Name ─────────────────────────────────────────────────────
            Text("Video Downloader")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 12)

            // ── Version ──────────────────────────────────────────────────────
            Text(versionLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Divider()
                .padding(.vertical, 16)

            // ── Author ───────────────────────────────────────────────────────
            Text("Desenvolvido por")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("Carlos Felipe Araújo")
                .font(.footnote)
                .fontWeight(.bold)
                .padding(.top, 2)

            // ── GitHub Link ───────────────────────────────────────────────────
            Link(destination: URL(string: "https://github.com/carlosxfelipe")!) {
                Label("github.com/carlosxfelipe", systemImage: "link")
                    .font(.footnote)
            }
            .padding(.top, 6)
            // ── Pix ───────────────────────────────────────────────────────────
            Divider()
                .padding(.vertical, 16)

            PixDonationView()
                .padding(.bottom, 20)
        }
        .frame(width: 260)
    }
}

// MARK: - Pix Donation

private struct PixDonationView: View {
    private let pixKey = "e3921fb5-d50e-4bda-93d2-43bb3d998b7b"
    @State private var copied = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Text("Gostou do app? \(Image(systemName: "cup.and.saucer.fill"))")
                .font(.footnote)
                .fontWeight(.semibold)

            Text("Considere fazer uma contribuição via Pix")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            let payload = pixEMVPayload(
                key: pixKey,
                name: "Carlos Araujo",
                city: "Brasil"
            )

            if let qrImage = generateQRCode(from: payload, isDarkMode: colorScheme == .dark) {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .padding(6)
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: copyPix) {
                HStack(spacing: 5) {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(copied ? .green : .accentColor)
                        .font(.caption)
                    Text(copied ? "Chave copiada!" : "Copiar chave Pix")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - PIX EMV payload (padrão Banco Central do Brasil)

    /// Formata um campo EMV: ID (2 dígitos) + comprimento (2 dígitos) + valor
    private func emv(_ id: String, _ value: String) -> String {
        String(format: "%@%02d%@", id, value.count, value)
    }

    private func pixEMVPayload(key: String, name: String, city: String) -> String {
        // Campo 26 — Merchant Account Information (PIX)
        let gui = emv("00", "br.gov.bcb.pix")
        let pixKeyField = emv("01", key)
        let merchantInfo = emv("26", gui + pixKeyField)

        // Campo 62 — Additional Data Field (txid obrigatório)
        let txid = emv("05", "***")
        let additionalData = emv("62", txid)

        var payload = ""
        payload += emv("00", "01") // Payload Format Indicator
        payload += merchantInfo // Merchant Account Info
        payload += emv("52", "0000") // Merchant Category Code
        payload += emv("53", "986") // Moeda (986 = BRL)
        payload += emv("58", "BR") // País
        payload += emv("59", String(name.prefix(25))) // Nome do recebedor
        payload += emv("60", String(city.prefix(15))) // Cidade
        payload += additionalData // Dados adicionais
        payload += "6304" // CRC placeholder

        // CRC16/CCITT-FALSE (poly 0x1021, init 0xFFFF)
        let crc = crc16CCITT(payload)
        payload += String(format: "%04X", crc)

        return payload
    }

    private func crc16CCITT(_ string: String) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in string.utf8 {
            crc ^= UInt16(byte) << 8
            for _ in 0 ..< 8 {
                crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1
            }
        }
        return crc
    }

    // MARK: - QR Code

    private func generateQRCode(from string: String, isDarkMode: Bool) -> NSImage? {
        guard let data = string.data(using: .utf8),
              let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }

        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")

        guard let qrImage = qrFilter.outputImage,
              let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }

        colorFilter.setValue(qrImage, forKey: "inputImage")
        // QR Code module (dark part) -> White in dark mode, Black in light mode
        colorFilter.setValue(isDarkMode ? CIColor.white : CIColor.black, forKey: "inputColor0")
        // Background (light part) -> Clear
        colorFilter.setValue(CIColor.clear, forKey: "inputColor1")

        guard let coloredImage = colorFilter.outputImage else { return nil }

        let scaled = coloredImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    // MARK: - Copy

    private func copyPix() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pixKey, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { copied = false }
        }
    }
}

#Preview {
    AboutView()
}
