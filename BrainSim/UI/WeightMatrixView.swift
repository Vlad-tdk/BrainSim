// UI/WeightMatrixView.swift
// Heatmap of average absolute synaptic weights per neuron row.
// Gives a quick read on which neurons have strong outputs.

import SwiftUI

struct WeightMatrixView: View {
    /// Row sums: one value per pre-neuron, normalised to [0,1]
    let rows: [Double]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard !rows.isEmpty else { return }
                let cellW = size.width  / CGFloat(rows.count)
                let cellH = size.height

                for (i, val) in rows.enumerated() {
                    let rect = CGRect(x: CGFloat(i) * cellW, y: 0, width: cellW, height: cellH)
                    // Hue: 0.66 (blue) at 0 → 0.0 (red) at 1
                    let hue = 0.66 - 0.66 * val
                    ctx.fill(
                        Path(rect),
                        with: .color(Color(hue: hue, saturation: 0.9, brightness: 0.85, opacity: 0.85))
                    )
                }
            }
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
