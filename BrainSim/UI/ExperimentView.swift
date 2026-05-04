// UI/ExperimentView.swift
// Sheet-style panel to run PatternExperiment and display results.

import SwiftUI

struct ExperimentView: View {
    @ObservedObject var experiment: PatternExperiment
    let network: Network
    let sim: Simulator

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Header ─────────────────────────────────────────
            HStack {
                Image(systemName: "flask.fill")
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .cyan], startPoint: .top, endPoint: .bottom)
                    )
                Text("Pattern Experiment")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            Text("Trains the network on Pattern A, then probes both A and B.\nMeasures which neurons specialised via STDP.")
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)

            Divider().background(Color.white.opacity(0.08))

            // ── Run button + progress ──────────────────────────
            HStack(spacing: 12) {
                // Step count controls
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Train steps")
                            .font(.caption2).foregroundColor(.gray)
                        HStack {
                            Slider(value: Binding(
                                get: { Double(experiment.trainStepsCount) },
                                set: { experiment.trainStepsCount = Int($0) }
                            ), in: 50...1000, step: 50)
                            .tint(.green)
                            Text("\(experiment.trainStepsCount)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                                .frame(width: 36)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Probe steps")
                            .font(.caption2).foregroundColor(.gray)
                        HStack {
                            Slider(value: Binding(
                                get: { Double(experiment.probeStepsCount) },
                                set: { experiment.probeStepsCount = Int($0) }
                            ), in: 20...200, step: 10)
                            .tint(.cyan)
                            Text("\(experiment.probeStepsCount)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.cyan)
                                .frame(width: 36)
                        }
                    }
                }

                // Run button
                Button {
                    experiment.run(network: network, sim: sim)
                } label: {
                    Label(experiment.isRunning ? "Running…" : "Run Experiment", systemImage: "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green.opacity(0.8))
                .disabled(experiment.isRunning)
            }

            if experiment.isRunning || experiment.progress > 0 {
                ProgressView(value: experiment.progress)
                    .tint(.green)
            }

            // ── Log ────────────────────────────────────────────
            if !experiment.log.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(experiment.log.enumerated()), id: \.offset) { _, line in
                        Text("> " + line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // ── Selectivity chart ──────────────────────────────
            if !experiment.selectivity.isEmpty {
                Divider().background(Color.white.opacity(0.08))

                Text("NEURON SELECTIVITY")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
                    .tracking(2)

                SelectivityView(data: experiment.selectivity)
                    .frame(height: 120)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: .green, label: "A-selective (score > 0.5): \(experiment.selectivity.filter { $0.score > 0.5 }.count)")
                    legendItem(color: .red,   label: "B-selective (score < -0.5): \(experiment.selectivity.filter { $0.score < -0.5 }.count)")
                    legendItem(color: .gray,  label: "Silent / mixed: \(experiment.selectivity.filter { abs($0.score) <= 0.5 }.count)")
                }
                .padding(.top, 4)

                // Top-5 most selective neurons table
                Divider().background(Color.white.opacity(0.08))
                Text("TOP SELECTIVE NEURONS")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
                    .tracking(2)

                let top5 = Array(experiment.selectivity.sorted { abs($0.score) > abs($1.score) }.prefix(8))
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow {
                        Text("Neuron").font(.caption2).foregroundColor(.gray)
                        Text("Score").font(.caption2).foregroundColor(.gray)
                        Text("Rate A").font(.caption2).foregroundColor(.gray)
                        Text("Rate B").font(.caption2).foregroundColor(.gray)
                        Text("Type").font(.caption2).foregroundColor(.gray)
                    }
                    ForEach(top5) { n in
                        GridRow {
                            Text("#\(n.id)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                            Text(String(format: "%.3f", n.score))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(n.score > 0 ? .green : .red)
                            Text(String(format: "%.3f", n.firesA))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.cyan)
                            Text(String(format: "%.3f", n.firesB))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.orange)
                            Text(abs(n.score) > 0.5 ? (n.score > 0 ? "→ A" : "→ B") : "mixed")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color(white: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.8))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}
