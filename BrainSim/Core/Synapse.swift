// Core/Synapse.swift
// Directed connection between two neurons.
// Implements Spike-Timing-Dependent Plasticity (STDP)
// with asymmetric Hebbian rule.

import Foundation

final class Synapse {

    // Synaptic weight ∈ [0, maxWeight]
    var weight: Double

    // STDP eligibility traces
    var preTrace: Double = 0     // A+ : potentiation
    var postTrace: Double = 0    // A- : depression

    // Parameters
    let tauTrace: Double         // trace decay factor per step
    let learningRateUp: Double   // LTP strength
    let learningRateDown: Double // LTD strength
    let maxWeight: Double
    let isInhibitory: Bool

    init(
        weight: Double = Double.random(in: 0.1...0.5),
        tauTrace: Double = 0.95,
        learningRateUp: Double = 0.01,
        learningRateDown: Double = 0.012,
        maxWeight: Double = 1.0,
        isInhibitory: Bool = false
    ) {
        self.weight = isInhibitory ? -abs(weight) : weight
        self.tauTrace = tauTrace
        self.learningRateUp = learningRateUp
        self.learningRateDown = learningRateDown
        self.maxWeight = maxWeight
        self.isInhibitory = isInhibitory
    }

    /// Update synapse with STDP rule for one time step.
    func update(preSpike: Bool, postSpike: Bool) {
        // Exponential trace decay
        preTrace  *= tauTrace
        postTrace *= tauTrace

        // Pre fires → LTD (since post fired before pre, this is anti-causal)
        if preSpike {
            preTrace += 1
            let delta = learningRateDown * postTrace
            weight -= isInhibitory ? -delta : delta
        }

        // Post fires → LTP (since pre fired before post, this is causal)
        if postSpike {
            postTrace += 1
            let delta = learningRateUp * preTrace
            weight += isInhibitory ? -delta : delta
        }

        // Clip weight to valid range
        let lo = isInhibitory ? -maxWeight : 0
        let hi = isInhibitory ? 0 : maxWeight
        weight = min(max(weight, lo), hi)
    }

    /// Effective current contribution when pre-neuron fires.
    var efficacy: Double { weight }
}
