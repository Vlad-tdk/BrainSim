// UI/SelectivityView.swift
// Bar chart showing per-neuron selectivity score after PatternExperiment.
// Green bar  →  neuron selective to Pattern A (+1)
// Red bar    →  neuron selective to Pattern B (-1)
// Grey       →  not selective (≈ 0)

import SwiftUI

struct SelectivityView: View {
    let data: [NeuronSelectivity]

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard !data.isEmpty else { return }
                let barW = size.width / CGFloat(data.count)
                let midY = size.height / 2

                // Zero line
                ctx.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: midY))
                        p.addLine(to: CGPoint(x: size.width, y: midY))
                    },
                    with: .color(.white.opacity(0.15)),
                    lineWidth: 1
                )

                for (i, item) in data.enumerated() {
                    let x = CGFloat(i) * barW
                    let h = abs(CGFloat(item.score)) * midY
                    let isA = item.score >= 0
                    let y = isA ? midY - h : midY

                    let rect = CGRect(x: x + 0.5, y: y, width: max(barW - 1, 1), height: h)
                    let colour: Color = abs(item.score) < 0.1
                        ? .gray.opacity(0.3)
                        : (isA ? .green : .red)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(colour.opacity(0.85)))
                }
            }
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
