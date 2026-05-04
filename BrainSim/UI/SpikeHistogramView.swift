// UI/SpikeHistogramView.swift
// Bar chart of spike counts over recent steps.
// Rendered with SwiftUI Canvas for zero dependencies.

import SwiftUI

struct SpikeHistogramView: View {
    let data: [Int]
    let maxVisible: Int = 300

    private var visibleData: [Int] { Array(data.suffix(maxVisible)) }
    private var peak: Int { visibleData.max() ?? 1 }

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let bars = visibleData
                guard !bars.isEmpty else { return }

                let barW = size.width / CGFloat(bars.count)
                let maxH = size.height

                for (i, val) in bars.enumerated() {
                    let fraction = CGFloat(val) / CGFloat(max(peak, 1))
                    let barH = fraction * maxH
                    let x = CGFloat(i) * barW
                    let rect = CGRect(x: x, y: maxH - barH, width: max(barW - 0.5, 0.5), height: barH)

                    let hue = 0.55 - 0.45 * Double(fraction)  // cyan → purple
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: 1),
                        with: .color(Color(hue: hue, saturation: 0.85, brightness: 0.95))
                    )
                }

                // Zero baseline
                ctx.stroke(
                    Path { p in p.move(to: CGPoint(x: 0, y: maxH)); p.addLine(to: CGPoint(x: size.width, y: maxH)) },
                    with: .color(.white.opacity(0.15)),
                    lineWidth: 1
                )
            }
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
