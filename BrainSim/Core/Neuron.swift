// Core/Neuron.swift
// Izhikevich (2003) spiking neuron model.
// Two-variable system that reproduces ~20 biologically realistic
// firing patterns depending on (a,b,c,d) parameters.

import Foundation

// MARK: - Neuron type presets

enum NeuronType {
    case regularSpiking    // RS – typical cortical excitatory
    case fastSpiking       // FS – cortical inhibitory interneuron
    case intrinsicallyBursting  // IB

    var params: (a: Double, b: Double, c: Double, d: Double) {
        switch self {
        case .regularSpiking:         return (0.02,  0.2, -65.0, 8.0)
        case .fastSpiking:            return (0.1,   0.2, -65.0, 2.0)
        case .intrinsicallyBursting:  return (0.02,  0.2, -55.0, 4.0)
        }
    }
}

// MARK: - Neuron

final class Neuron {

    // State variables
    var v: Double          // membrane potential (mV)
    var u: Double          // recovery variable

    // Parameters
    let a: Double
    let b: Double
    let c: Double          // reset potential
    let d: Double          // after-spike reset of u

    // Spike trace used by STDP (exponential decay)
    var spikeTrace: Double = 0

    // Homeostatic target firing rate (spikes / step, smoothed)
    var firingRateSmoothed: Double = 0
    let targetFiringRate: Double = 0.05

    // Unique id for visualisation
    let id: Int

    init(id: Int, type: NeuronType = .regularSpiking) {
        self.id = id
        let p = type.params
        self.a = p.a; self.b = p.b; self.c = p.c; self.d = p.d
        self.v = p.c
        self.u = p.b * p.c
    }

    /// Advance the neuron by one time step (dt = 0.5 ms × 2 sub-steps).
    /// Returns true if the neuron fired this step.
    @discardableResult
    func step(input: Double, dt: Double = 0.5) -> Bool {
        // Two sub-steps of dt = 0.5 ms for numerical stability
        for _ in 0..<2 {
            v += dt * (0.04*v*v + 5*v + 140 - u + input)
            u += dt * (a*(b*v - u))
        }

        // Decay trace
        spikeTrace *= 0.95

        if v >= 30 {
            v = c
            u += d
            spikeTrace += 1
            firingRateSmoothed = 0.99 * firingRateSmoothed + 0.01
            return true
        }

        firingRateSmoothed = 0.99 * firingRateSmoothed
        return false
    }

    /// Intrinsic plasticity: scales input to keep firing near target rate.
    var homeostasisScale: Double {
        let error = targetFiringRate - firingRateSmoothed
        return max(0.5, min(2.0, 1.0 + 5 * error))
    }
}
