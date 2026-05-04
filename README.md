# BrainSim

A real-time Spiking Neural Network simulator for macOS, written entirely in Swift — no ML frameworks, no external dependencies.

![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift) ![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey?logo=apple) ![License](https://img.shields.io/badge/license-MIT-green)

---

## What is this?

Classical neural networks (transformers, CNNs) process batches of floating-point vectors and learn through backpropagation. BrainSim takes a different approach: it simulates individual biological neurons that communicate via discrete spikes in time, and learns continuously through a local synaptic rule called STDP — the same mechanism believed to underlie learning in real cortex.

This is **third-generation neural network** territory. No gradient descent. No loss function. The network organizes itself.

---

## Features

- **Izhikevich neuron model** — two-equation system that reproduces a wide range of real neuron firing patterns (Regular Spiking, Fast Spiking Inhibitory, Chattering) with minimal computational cost
- **STDP learning** — synaptic weights update based on the relative timing of pre- and post-synaptic spikes; causally correlated neurons strengthen their connections automatically
- **Homeostasis** — each neuron continuously adjusts its own excitability to maintain a target firing rate, preventing runaway excitation or total silence
- **Live visualization** — spike raster, weight heatmap, weight distribution histogram, all rendered at interactive framerates via SwiftUI Canvas
- **Pattern experiment** — train on Pattern A, then probe with A and B; watch selectivity scores emerge in neurons that have never been explicitly labeled

---

## Architecture

```
BrainSim/
├── Core/
│   ├── Neuron.swift          # Izhikevich model: v/u state, step(), spike detection
│   ├── Synapse.swift         # Weight + STDP traces (pre/post), update()
│   └── Network.swift         # N×N connectivity, single-step forward pass
├── Runtime/
│   ├── Simulator.swift       # Background simulation loop, publishes state to UI
│   └── PatternExperiment.swift  # Isolated train→test pipeline, selectivity scoring
└── UI/
    ├── RasterView.swift      # Spike raster: time × neuron, Canvas-rendered
    ├── HeatmapView.swift     # Synaptic weight matrix
    ├── HistogramView.swift   # Weight distribution + selectivity bars
    └── ControlPanel.swift    # Input mode, speed, neuron count, experiment launcher
```

The `Core` layer has no UIKit/SwiftUI imports and is designed to port 1:1 to Rust when you need to scale beyond a few hundred neurons.

---

## Neuron model

BrainSim uses the **Izhikevich (2003)** model — a dimensionless reduction of Hodgkin-Huxley that runs in O(1) per neuron per timestep:

```
v' = 0.04v² + 5v + 140 − u + I
u' = a(bv − u)

if v ≥ 30 mV:  v ← c,  u ← u + d   (spike + reset)
```

Two neuron types are included:

| Type | a | b | c | d | Behavior |
|---|---|---|---|---|---|
| Regular Spiking | 0.02 | 0.2 | −65 | 8 | Tonic spiking, adapts over time |
| Fast Spiking | 0.1 | 0.2 | −65 | 2 | Rapid bursts, no adaptation |

---

## Learning rule (STDP)

Each synapse maintains two exponentially decaying eligibility traces:

```swift
preTrace  *= τ          // τ = 0.95 per timestep
postTrace *= τ

if preSpiked:
    preTrace  += 1
    weight    += A₊ × postTrace    // LTP: post fired recently → strengthen

if postSpiked:
    postTrace += 1
    weight    -= A₋ × preTrace     // LTD: pre fired recently → weaken

weight = clamp(weight, 0, 1)
```

`A₊ = 0.008`, `A₋ = 0.010` by default. The asymmetry biases toward depression, keeping average weights bounded without explicit normalization.

---

## Getting started

**Requirements:** Xcode 15+, macOS 14 Sonoma or later.

```bash
git clone https://github.com/yourname/BrainSim.git
cd BrainSim
open BrainSim.xcodeproj
```

Select the **BrainSim (macOS)** scheme, press **⌘R**.

No package dependencies to resolve. No API keys. Runs offline.

---

## Experiments

### 1. Cluster formation

Switch Input Mode to **Pattern A**. On the Raster tab, watch initially random spikes coalesce into vertical stripes over ~200 timesteps. These stripes are groups of neurons that STDP has synchronized because they reliably co-activate under the pattern.

### 2. Selectivity test

Open the **Experiment** tab. Set train steps (300 is a good default) and click **Run Experiment**. The network trains on Pattern A, then is probed silently with brief flashes of A and B. The selectivity histogram shows:

- **Green bars** — neurons that learned to respond preferentially to Pattern A (score > 0.5)
- **Red bars** — neurons that preferentially respond to the unseen Pattern B

No labels were provided at any point. The structure emerged from timing alone.

### 3. Homeostasis under silence

After training, switch Input Mode to **Silence**. The network does not stop immediately. Residual activity echoes through strengthened pathways for several hundred timesteps. As homeostasis raises excitability thresholds in response to the absence of input, spontaneous noise-driven spikes eventually take over — the same phenomenon observed in sensory deprivation experiments.

---

## Performance notes

| Network size | Timestep duration (M2 Pro) | Sustainable FPS |
|---|---|---|
| 20 neurons | ~0.05 ms | 60 fps |
| 50 neurons | ~0.3 ms | 60 fps |
| 100 neurons | ~1.2 ms | 40–60 fps |
| 200 neurons | ~5 ms | 15–20 fps |

The bottleneck at larger sizes is the O(N²) synapse update loop. Parallelizing with `vDSP` matrix multiply or porting `Core` to Rust/Metal removes this ceiling entirely.

---

## Roadmap

- [ ] Inhibitory interneurons (E/I balance)
- [ ] Configurable topology (random sparse, small-world, columnar)
- [ ] Metal compute shader for N > 1000
- [ ] Export spike trains to CSV / NumPy `.npy`
- [ ] Sequence prediction benchmark (A→B→C recall)
- [ ] iOS companion app (view-only, connects to macOS over Bonjour)

---

## Why Swift, not Python?

Python + Brian2 is the standard for SNN research. BrainSim exists for a different reason: to build something you can hand to anyone with a Mac, double-click, and immediately see a brain simulate in real time — no conda environment, no Jupyter notebook, no `pip install`. SwiftUI Canvas gives genuine 60 fps rendering of live neural activity with about 50 lines of drawing code. The tradeoff is scale: for experiments beyond ~200 neurons, the `Core` layer should be rewritten in Rust and called via FFI. The interfaces are designed for exactly that migration.

---

## References

- Izhikevich, E.M. (2003). *Simple model of spiking neurons.* IEEE Transactions on Neural Networks, 14(6), 1569–1572.
- Bi, G. & Poo, M. (1998). *Synaptic modifications in cultured hippocampal neurons.* Journal of Neuroscience, 18(24), 10464–10472.
- Turrigiano, G.G. (2008). *The self-tuning neuron: synaptic scaling of excitatory synapses.* Cell, 135(3), 422–435.

---

## License

MIT. Use it, break it, port it to Rust.