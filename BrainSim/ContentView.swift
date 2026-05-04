// ContentView.swift
// Root layout: sidebar + tabbed main area (Raster | Experiment | Log)
// Tabs: Raster (live spike plot) | Experiment (STDP test) | Log (console)

import SwiftUI

struct ContentView: View {
    @StateObject private var sim = Simulator()
    @StateObject private var experiment = PatternExperiment()
    @State private var selectedTab: Tab = .raster

    enum Tab: String, CaseIterable {
        case raster     = "Raster"
        case experiment = "Experiment"
        case log        = "Log"

        var icon: String {
            switch self {
            case .raster:     return "waveform.path.ecg.rectangle"
            case .experiment: return "flask.fill"
            case .log:        return "terminal"
            }
        }
    }

    // Per-neuron activity from raster window (used in experiment proxy heatmap)
    private var activityRows: [Double] {
        let n = sim.networkSize
        guard n > 0 else { return [] }
        var counts = Array(repeating: 0, count: n)
        for e in sim.rasterWindow where e.neuronIndex < n {
            counts[e.neuronIndex] += 1
        }
        let peak = Double(counts.max() ?? 1)
        return counts.map { peak > 0 ? Double($0) / peak : 0 }
    }

    var body: some View {
        HStack(spacing: 0) {

            // ── Sidebar ──────────────────────────────────────────────
            ControlPanelView(sim: sim)

            // ── Main area ────────────────────────────────────────────
            VStack(spacing: 0) {

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        TabBarButton(tab: tab, selected: selectedTab == tab) {
                            selectedTab = tab
                        }
                    }
                    Spacer()

                    // Live pill
                    HStack(spacing: 5) {
                        Circle()
                            .fill(sim.isRunning ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                       value: sim.isRunning)
                        Text("t=\(sim.currentStep)  spikes=\(sim.spikesPerStep.last ?? 0)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.06))
                    .clipShape(Capsule())
                    .padding(.trailing, 12)
                }
                .background(Color(white: 0.07))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }

                // Content
                Group {
                    switch selectedTab {
                    case .raster:
                        rasterTab
                    case .experiment:
                        experimentTab
                    case .log:
                        logTab
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(white: 0.05))
            }
        }
        .background(Color(white: 0.05))
        .preferredColorScheme(.dark)
    }

    // MARK: - Raster tab

    private var rasterTab: some View {
        VStack(spacing: 10) {
            // Description card
            HStack(spacing: 12) {
                infoCard(
                    icon: "dot.radiowaves.right",
                    title: "Spike Raster",
                    body: "Each dot = 1 spike. Time → right, neurons ↑. Watch clusters form as STDP trains."
                )
                infoCard(
                    icon: "arrow.up.arrow.down.circle",
                    title: "STDP Learning",
                    body: "Co-firing neurons strengthen. Anti-correlated weaken. No backprop — pure local rules."
                )
                infoCard(
                    icon: "waveform.badge.magnifyingglass",
                    title: "What to watch",
                    body: "Switch A→B: different neuron group lights up. That's specialisation. Run Experiment to measure it."
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Raster (main)
            RasterView(
                events: sim.rasterWindow,
                currentStep: sim.currentStep,
                neuronCount: sim.networkSize
            )
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)

            // Bottom row
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    label("Spike Rate History")
                    SpikeHistogramView(data: sim.spikesPerStep)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    label("Neuron Activity Heatmap")
                    WeightMatrixView(rows: activityRows)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 110)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Experiment tab

    private var experimentTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Explainer
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What this measures")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("The experiment trains the network 300 steps on Pattern A (every even neuron gets strong input), then probes both patterns. Neurons that only fire for A get score +1, only for B get -1. This is evidence that STDP caused real specialisation — without backprop, without labels.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(Color.yellow.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow.opacity(0.15), lineWidth: 1))

                ExperimentView(experiment: experiment, network: sim.network, sim: sim)
            }
            .padding(20)
        }
    }

    // MARK: - Log tab

    private var logTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 3) {
                let lines = buildLogLines()
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.green.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
        .background(Color.black.opacity(0.5))
    }

    private func buildLogLines() -> [String] {
        var lines: [String] = ["// BrainSim console — last 50 steps", ""]
        let tail = sim.spikesPerStep.suffix(50).reversed().enumerated()
        for (i, spikes) in tail {
            let t = sim.currentStep - i - 1
            if t >= 0 {
                let bar = String(repeating: "█", count: min(spikes, 40))
                lines.append(String(format: "t=%05d  spikes=%02d  %@", t, spikes, bar))
            }
        }
        return lines
    }

    // MARK: - Helpers

    @ViewBuilder
    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.gray.opacity(0.7))
            .tracking(0.5)
    }

    @ViewBuilder
    private func infoCard(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cyan)
            Text(body)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cyan.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.cyan.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - Tab bar button

private struct TabBarButton: View {
    let tab: ContentView.Tab
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tab.icon).font(.system(size: 11))
                Text(tab.rawValue).font(.system(size: 12, weight: selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? .white : .gray)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                if selected {
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(height: 2)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }
}

#Preview {
    ContentView().frame(width: 1060, height: 680)
}

