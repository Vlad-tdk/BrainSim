// UI/ControlPanelView.swift
// Scrollable left-side control panel.

import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var sim: Simulator
    @State private var sizeText: String = "50"

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // ── Logo ────────────────────────────────────────────
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(colors: [.cyan, .purple],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text("BrainSim")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Izhikevich · STDP")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1)
                    }
                }

                divider()

                // ── Playback ────────────────────────────────────────
                section("Simulation")

                HStack(spacing: 8) {
                    ControlButton(
                        icon: sim.isRunning ? "pause.fill" : "play.fill",
                        label: sim.isRunning ? "Pause" : "Run",
                        tint: sim.isRunning ? .orange : .green
                    ) { sim.isRunning ? sim.stop() : sim.start() }

                    ControlButton(icon: "arrow.counterclockwise", label: "Reset", tint: .red) {
                        sim.reset()
                    }
                }

                LabeledSlider(label: "Speed", value: $sim.speedMultiplier, range: 1...20, format: "×%.0f")

                divider()

                // ── Input ───────────────────────────────────────────
                section("Input Mode")

                ForEach(InputMode.allCases) { mode in
                    ModeRow(mode: mode, selected: sim.inputMode == mode) {
                        sim.inputMode = mode
                    }
                }

                LabeledSlider(label: "Strength", value: $sim.inputStrength, range: 0...20, format: "%.1f nA")

                divider()

                // ── Network ─────────────────────────────────────────
                section("Network")

                HStack(spacing: 6) {
                    Text("Neurons")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    TextField("50", text: $sizeText)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                    Button("Apply") {
                        if let n = Int(sizeText), (4...200).contains(n) {
                            sim.rebuild(size: n)
                            sizeText = "\(n)"
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan.opacity(0.7))
                    .controlSize(.mini)
                }

                divider()

                // ── Live stats ──────────────────────────────────────
                section("Live Stats")

                statsRow("Step",       value: "\(sim.currentStep)")
                statsRow("Spikes/step", value: "\(sim.spikesPerStep.last ?? 0)")
                statsRow("Avg weight", value: String(format: "%.4f", sim.averageWeight))
                statsRow("Firing rate", value: {
                    let recent = sim.spikesPerStep.suffix(20)
                    let avg = recent.isEmpty ? 0 : recent.reduce(0, +) / recent.count
                    return "\(avg) / \(sim.networkSize)"
                }())

                divider()

                // ── Legend ──────────────────────────────────────────
                VStack(alignment: .leading, spacing: 5) {
                    legendDot(.cyan, "Excitatory (RS)")
                    legendDot(.red,  "Inhibitory (FS, ~20%)")
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer(minLength: 20)
            }
            .padding(14)
        }
        .frame(width: 210)
        .background(Color(white: 0.08))
    }

    // MARK: - Helpers

    @ViewBuilder private func divider() -> some View {
        Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
    }

    @ViewBuilder private func section(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(Color.gray.opacity(0.7))
            .tracking(1.5)
    }

    @ViewBuilder private func statsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.cyan)
        }
    }

    @ViewBuilder private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
    }
}

// MARK: - Mode row button

private struct ModeRow: View {
    let mode: InputMode
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: modeIcon)
                    .font(.system(size: 11))
                    .frame(width: 16)
                Text(mode.rawValue)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                Spacer()
                if selected {
                    Circle().fill(Color.cyan).frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .foregroundColor(selected ? .cyan : .gray)
            .background(selected ? Color.cyan.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(selected ? Color.cyan.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var modeIcon: String {
        switch mode {
        case .random:   return "shuffle"
        case .patternA: return "waveform.path.ecg"
        case .patternB: return "waveform"
        case .silence:  return "speaker.slash"
        }
    }
}

// MARK: - Reusable subcomponents

private struct ControlButton: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundColor(tint)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(tint.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption).foregroundColor(.gray)
                Spacer()
                Text(String(format: format, value))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            Slider(value: $value, in: range).tint(.cyan)
        }
    }
}
