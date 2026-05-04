// UI/LogStripView.swift
// Scrolling console log of recent simulation events.

import SwiftUI

struct LogStripView: View {
    @ObservedObject var sim: Simulator

    // Build log lines from published state
    private var lines: [String] {
        var out: [String] = []
        if let last = sim.spikesPerStep.last {
            out.append("t=\(sim.currentStep)  spikes=\(last)  avgW=\(String(format: "%.4f", sim.averageWeight))  mode=\(sim.inputMode.rawValue)")
        }
        // Show last 4 steps
        let tail = sim.spikesPerStep.suffix(4).reversed().enumerated()
        for (i, v) in tail {
            let t = sim.currentStep - i - 1
            if t >= 0 { out.append("t=\(t)  spikes=\(v)") }
        }
        return out
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text("> " + line)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.green.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.green.opacity(0.15), lineWidth: 1)
        )
    }
}
