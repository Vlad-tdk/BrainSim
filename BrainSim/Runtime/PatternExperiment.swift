// Runtime/PatternExperiment.swift
// Measures per-neuron selectivity after STDP training on Pattern A.
//
// Selectivity ∈ [-1, +1]:
//   +1  → fires ONLY during Pattern A presentation
//   -1  → fires ONLY during Pattern B presentation
//    0  → no preference (mixed or silent)
//
// Runs in batches with Task.yield() so the UI stays responsive.

import Foundation
import Combine

struct NeuronSelectivity: Identifiable {
    let id: Int
    var score: Double   // ∈ [-1, +1]
    var firesA: Double  // spikes/step during probe A
    var firesB: Double  // spikes/step during probe B
}

@MainActor
final class PatternExperiment: ObservableObject {

    @Published var selectivity: [NeuronSelectivity] = []
    @Published var isRunning = false
    @Published var progress: Double = 0
    @Published var log: [String] = []
    @Published var trainStepsCount: Int = 300
    @Published var probeStepsCount: Int = 50

    private weak var simRef: Simulator?

    func run(network: Network, sim: Simulator) {
        guard !isRunning else { return }

        // Pause simulation so the experiment owns the network exclusively
        sim.stop()
        simRef = sim

        isRunning = true
        progress = 0
        log = []
        selectivity = []

        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.execute(network: network)
        }
    }

    // MARK: - Main execution (yields every batch so UI refreshes)

    private func execute(network: Network) async {
        let n = network.size
        let train = trainStepsCount
        let probe  = probeStepsCount
        let total  = Double(train + probe * 2)
        let batchSize = 10   // steps between yield points

        // ── Phase 1: Train on Pattern A ─────────────────────────
        appendLog("▶ Training on Pattern A (\(train) steps)…")

        var t = 0
        while t < train {
            let end = min(t + batchSize, train)
            for _ in t..<end {
                network.step(externalInput: network.patternA)
            }
            t = end
            progress = Double(t) / total
            await Task.yield()   // let SwiftUI redraw + timer events through
        }

        // ── Phase 2: Probe A ─────────────────────────────────────
        appendLog("🔬 Probing Pattern A (\(probe) steps)…")
        var countA = Array(repeating: 0.0, count: n)
        var p = 0
        while p < probe {
            let end = min(p + batchSize, probe)
            for _ in p..<end {
                let spikes = network.step(externalInput: network.patternA, isTraining: false)
                for i in spikes.indices where spikes[i] { countA[i] += 1 }
            }
            p = end
            progress = Double(train + p) / total
            await Task.yield()
        }
        let rateA = countA.map { $0 / Double(probe) }

        // ── Phase 3: Probe B ─────────────────────────────────────
        appendLog("🔬 Probing Pattern B (\(probe) steps)…")
        var countB = Array(repeating: 0.0, count: n)
        p = 0
        while p < probe {
            let end = min(p + batchSize, probe)
            for _ in p..<end {
                let spikes = network.step(externalInput: network.patternB, isTraining: false)
                for i in spikes.indices where spikes[i] { countB[i] += 1 }
            }
            p = end
            progress = Double(train + probe + p) / total
            await Task.yield()
        }
        let rateB = countB.map { $0 / Double(probe) }

        // ── Compute selectivity ───────────────────────────────────
        var results: [NeuronSelectivity] = []
        for i in 0..<n {
            let a = rateA[i], b = rateB[i]
            let score = (a + b) > 0 ? (a - b) / (a + b) : 0
            results.append(NeuronSelectivity(id: i, score: score, firesA: a, firesB: b))
        }

        let selA    = results.filter { $0.score >  0.5 }.count
        let selB    = results.filter { $0.score < -0.5 }.count
        let silent  = results.filter { $0.firesA < 0.01 && $0.firesB < 0.01 }.count
        let mixed   = n - selA - selB - silent

        appendLog("")
        appendLog("✅ Results (\(n) neurons):")
        appendLog("   A-selective (score > +0.5): \(selA)")
        appendLog("   B-selective (score < -0.5): \(selB)")
        appendLog("   Mixed / non-selective:       \(mixed)")
        appendLog("   Silent (no response):        \(silent)")
        appendLog("")
        appendLog("   → STDP trained \(selA + selB)/\(n) neurons to specialise.")

        selectivity = results
        progress = 1.0
        isRunning = false
    }

    // MARK: - Helpers

    private func appendLog(_ line: String) {
        log.append(line)
    }
}
