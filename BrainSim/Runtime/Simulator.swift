// Runtime/Simulator.swift
// Observable engine that drives the simulation loop on a background thread
// and publishes state changes to SwiftUI.

import Foundation
import Combine

// MARK: - Input mode

enum InputMode: String, CaseIterable, Identifiable {
    case random   = "Random"
    case patternA = "Pattern A"
    case patternB = "Pattern B"
    case silence  = "Silence"
    var id: String { rawValue }
}

// MARK: - Spike record for raster plot

struct SpikeEvent: Identifiable {
    let id = UUID()
    let step: Int
    let neuronIndex: Int
}

// MARK: - Simulator

@MainActor
final class Simulator: ObservableObject {

    // ---- Published state ----
    @Published var isRunning = false
    @Published var currentStep = 0
    @Published var spikesPerStep: [Int] = []          // history of spike counts
    @Published var rasterWindow: [SpikeEvent] = []    // recent spikes for raster
    @Published var averageWeight: Double = 0
    @Published var networkSize: Int = 50
    @Published var inputMode: InputMode = .random
    @Published var inputStrength: Double = 10.0       // base driving current
    @Published var speedMultiplier: Double = 1.0      // steps per timer tick

    // ---- Internal ----
    // Internal but accessible to experiment runner
    var network: Network = Network(size: 50)
    private var timer: AnyCancellable?
    private let rasterWindowSize = 200                // steps shown in raster

    // MARK: - Control

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let interval = max(0.01, 0.05 / speedMultiplier)
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }

    func reset() {
        stop()
        network = Network(size: networkSize)
        currentStep = 0
        spikesPerStep = []
        rasterWindow = []
        averageWeight = 0
    }

    func rebuild(size: Int) {
        networkSize = size
        reset()
    }

    // MARK: - Simulation tick

    private func tick() {
        let stepsPerTick = max(1, Int(speedMultiplier))
        for _ in 0..<stepsPerTick {
            let input = buildInput()
            let spikes = network.step(externalInput: input)

            let spikeCount = spikes.filter { $0 }.count
            spikesPerStep.append(spikeCount)
            if spikesPerStep.count > 300 { spikesPerStep.removeFirst() }

            // Raster events
            for (idx, fired) in spikes.enumerated() where fired {
                rasterWindow.append(SpikeEvent(step: currentStep, neuronIndex: idx))
            }
            // Trim raster to window
            let cutoff = currentStep - rasterWindowSize
            rasterWindow.removeAll { $0.step < cutoff }

            currentStep += 1
        }

        averageWeight = network.averageWeight
    }

    // MARK: - Input builder

    private func buildInput() -> [Double] {
        let n = network.size
        switch inputMode {
        case .random:
            return (0..<n).map { _ in Double.random(in: 0...1) * inputStrength }
        case .patternA:
            return network.patternA.map { $0 * (inputStrength / 10) }
        case .patternB:
            return network.patternB.map { $0 * (inputStrength / 10) }
        case .silence:
            return Array(repeating: 0, count: n)
        }
    }
}
