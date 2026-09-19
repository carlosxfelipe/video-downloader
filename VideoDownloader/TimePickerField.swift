//
//  TimePickerField.swift
//  VideoDownloader
//
//  Created by Carlos Felipe Araújo on 13/09/26.
//

import SwiftUI

/// Campo de entrada de tempo no formato HH:MM:SS com segmentos individuais e steppers.
struct TimePickerField: View {
    let label: String
    @Binding var time: String

    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var isEnabled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(.checkbox)
                .onChange(of: isEnabled) { _, enabled in
                    time = enabled ? formatted() : ""
                }

            Text(label)
                .foregroundColor(isEnabled ? .primary : .secondary)
                .frame(width: 28, alignment: .trailing)

            HStack(spacing: 0) {
                segment(value: $hours, max: 99)
                separator()
                segment(value: $minutes, max: 59)
                separator()
                segment(value: $seconds, max: 59)
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.38)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            )
        }
        .onAppear(perform: syncFromString)
        .onChange(of: time) { _, newValue in
            if newValue.isEmpty {
                isEnabled = false
                hours = 0; minutes = 0; seconds = 0
            }
        }
    }

    private func segment(value: Binding<Int>, max maxVal: Int) -> some View {
        HStack(spacing: 1) {
            TextField("", value: value, formatter: twoDigit)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .frame(width: 24)
                .onChange(of: value.wrappedValue) { _, v in
                    value.wrappedValue = Swift.max(0, Swift.min(v, maxVal))
                    commit()
                }

            VStack(spacing: 0) {
                Button {
                    value.wrappedValue = Swift.min(value.wrappedValue + 1, maxVal)
                    commit()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 7, weight: .bold))
                }
                .buttonStyle(.plain)

                Button {
                    value.wrappedValue = Swift.max(value.wrappedValue - 1, 0)
                    commit()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(.secondary)
        }
    }

    private func separator() -> some View {
        Text(":").foregroundColor(.secondary).padding(.horizontal, 2)
    }

    private func commit() {
        guard isEnabled else { return }
        time = formatted()
    }

    private func formatted() -> String {
        String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func syncFromString() {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        if parts.count == 3 {
            hours = parts[0]; minutes = parts[1]; seconds = parts[2]
            isEnabled = true
        }
    }

    private var twoDigit: NumberFormatter {
        let f = NumberFormatter()
        f.minimumIntegerDigits = 2
        f.maximumIntegerDigits = 2
        return f
    }
}

#Preview {
    @Previewable @State var start = ""
    @Previewable @State var end = ""
    VStack(alignment: .leading, spacing: 10) {
        TimePickerField(label: "De", time: $start)
        TimePickerField(label: "Até", time: $end)
        Text("start: \"\(start)\"  end: \"\(end)\"")
            .font(.caption).foregroundColor(.secondary)
    }
    .padding()
}
