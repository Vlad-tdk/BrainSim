//
//  RasterView.swift
//  BrainSim
//
//  Created by Vladimir Martemianov on 4. 5. 2026..
//
// UI/RasterView.swift
// Spike raster plot: time on X-axis, neuron index on Y-axis.
// Each dot = one spike event. Rendered with Canvas for performance.

import SwiftUI

struct RasterView: View {
    let events: [SpikeEvent]
    let currentStep: Int
    let neuronCount: Int
    let windowSize: Int = 200

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let stepStart = currentStep - windowSize

                for event in events {
                    let xFrac = Double(event.step - stepStart) / Double(windowSize)
                    let yFrac = Double(event.neuronIndex) / Double(max(neuronCount - 1, 1))

                    let x = xFrac * w
                    let y = yFrac * h

                    let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)

                    // Colour by neuron group (inhibitory = red, excitatory = cyan)
                    let inhibitoryCount = max(1, Int(Double(neuronCount) * 0.2))
                    let isInhibitory = event.neuronIndex < inhibitoryCount
                    let colour = isInhibitory
                        ? Color(hue: 0.0, saturation: 0.9, brightness: 1.0)
                        : Color(hue: 0.52, saturation: 0.9, brightness: 1.0)

                    context.fill(Path(ellipseIn: rect), with: .color(colour))
                }

                // Vertical "now" cursor
                let nowX = w  // always at right edge
                context.stroke(
                    Path { p in p.move(to: CGPoint(x: nowX, y: 0)); p.addLine(to: CGPoint(x: nowX, y: h)) },
                    with: .color(.white.opacity(0.2)),
                    lineWidth: 1
                )
            }
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
