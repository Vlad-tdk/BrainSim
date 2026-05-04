import Foundation

@main
struct TestLogic {
    static func main() {
        print("Starting core network test...")
        
        // Create a network
        let network = Network(size: 50)
        
        let trainSteps = 300
        let probeSteps = 50
        
        print("Training on Pattern A for \(trainSteps) steps (STDP enabled)...")
        for _ in 0..<trainSteps {
            network.step(externalInput: network.patternA, isTraining: true)
        }
        
        print("Probing Pattern A for \(probeSteps) steps (STDP disabled)...")
        var countA = Array(repeating: 0.0, count: network.size)
        for _ in 0..<probeSteps {
            let spikes = network.step(externalInput: network.patternA, isTraining: false)
            for i in spikes.indices where spikes[i] { countA[i] += 1 }
        }
        let rateA = countA.map { $0 / Double(probeSteps) }
        
        print("Probing Pattern B for \(probeSteps) steps (STDP disabled)...")
        var countB = Array(repeating: 0.0, count: network.size)
        for _ in 0..<probeSteps {
            let spikes = network.step(externalInput: network.patternB, isTraining: false)
            for i in spikes.indices where spikes[i] { countB[i] += 1 }
        }
        let rateB = countB.map { $0 / Double(probeSteps) }
        
        // Calculate selectivity
        var selA = 0
        var selB = 0
        var silent = 0
        var mixed = 0
        
        for i in 0..<network.size {
            let a = rateA[i]
            let b = rateB[i]
            let score = (a + b) > 0 ? (a - b) / (a + b) : 0
            
            if score > 0.5 {
                selA += 1
            } else if score < -0.5 {
                selB += 1
            } else if a < 0.01 && b < 0.01 {
                silent += 1
            } else {
                mixed += 1
            }
        }
        
        print("   Results (\(network.size) neurons):")
        print("   A-selective (score > +0.5): \(selA)")
        print("   B-selective (score < -0.5): \(selB)")
        print("   Mixed / non-selective:       \(mixed)")
        print("   Silent (no response):        \(silent)")
        print("")
        print("   → STDP trained \(selA + selB)/\(network.size) neurons to specialise.")
        
        if selA > 0 {
            print("TEST PASSED: Network successfully learned to specialize on Pattern A.")
        } else {
            print("TEST FAILED: No neurons learned Pattern A.")
            exit(1)
        }
    }
}
