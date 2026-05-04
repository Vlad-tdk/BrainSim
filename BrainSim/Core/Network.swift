// Core/Network.swift
// Recurrent spiking network.
// Topology: fully-connected, with ~20 % random inhibitory neurons.

import Foundation

final class Network {

    let neurons: [Neuron]
    // synapses[i][j] = connection from neuron i → neuron j
    let synapses: [[Synapse]]
    let size: Int

    // Pattern input channels (used for A/B pattern testing)
    var patternA: [Double] = []
    var patternB: [Double] = []
    
    // Explicit array to hold spikes from the previous step
    private var prevSpikes: [Bool]

    init(size: Int, inhibitoryFraction: Double = 0.2) {
        self.size = size

        // ~20 % are fast-spiking inhibitory
        let inhibCount = Int(Double(size) * inhibitoryFraction)
        neurons = (0..<size).map { i in
            Neuron(id: i, type: i < inhibCount ? .fastSpiking : .regularSpiking)
        }
        
        prevSpikes = Array(repeating: false, count: size)

        let inhibSet = Set(0..<inhibCount)
        synapses = (0..<size).map { i in
            (0..<size).map { j in
                guard i != j else {
                    // Self-connection – zero weight, never used
                    return Synapse(weight: 0, maxWeight: 0)
                }
                return Synapse(
                    weight: Double.random(in: 0.05...0.4),
                    isInhibitory: inhibSet.contains(i)
                )
            }
        }

        // Default patterns: interleaved neurons
        patternA = (0..<size).map { $0 % 2 == 0 ? Double.random(in: 8...14) : 0 }
        patternB = (0..<size).map { $0 % 2 == 1 ? Double.random(in: 8...14) : 0 }
    }

    // MARK: - Forward step

    /// Run one simulation step.
    /// - Parameter externalInput: per-neuron driving current (length == size)
    /// - Parameter isTraining: if true, STDP learning is applied
    /// - Returns: spike boolean array
    @discardableResult
    func step(externalInput: [Double], isTraining: Bool = true) -> [Bool] {
        var spikes = Array(repeating: false, count: size)

        // 1. Step each neuron using previous step's spikes
        for i in neurons.indices {
            var synapticInput = 0.0
            for j in neurons.indices where j != i {
                if prevSpikes[j] {
                    synapticInput += synapses[j][i].efficacy
                }
            }
            let scaledExternal = externalInput[i] * neurons[i].homeostasisScale
            spikes[i] = neurons[i].step(input: synapticInput + scaledExternal)
        }

        // 2. STDP update for every synapse (only if training)
        if isTraining {
            for i in neurons.indices {
                for j in neurons.indices where i != j {
                    synapses[i][j].update(preSpike: spikes[i], postSpike: spikes[j])
                }
            }
        }
        
        // 3. Save current spikes for the next step
        prevSpikes = spikes

        return spikes
    }

    // MARK: - Helpers

    var averageWeight: Double {
        var total = 0.0, count = 0
        for i in neurons.indices {
            for j in neurons.indices where i != j {
                total += abs(synapses[i][j].weight)
                count += 1
            }
        }
        return count > 0 ? total / Double(count) : 0
    }
}
