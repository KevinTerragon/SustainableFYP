//
//  DashboardCard.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import SwiftUI

struct DashboardCard: View {
    let deviceName: String
    let watts: Double
    let costPerHour: Double
    let status: String
    let source: String
    let lastUpdated: Date
    let tips: String
    let samples: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(deviceName).font(.headline)
                Spacer()
                Text(status).font(.caption)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(status == "On" ? .green.opacity(0.2) : .yellow.opacity(0.2))
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Power")
                    Text("\(Int(watts)) W").font(.title2).monospacedDigit()
                }
                VStack(alignment: .leading) {
                    Text("Cost")
                    Text(String(format: "$%.3f/hr", costPerHour)).font(.title3).monospacedDigit()
                }
                VStack(alignment: .leading) {
                    Text("Source")
                    Text(source).font(.subheadline)
                }
            }

            Sparkline(values: samples)
                .frame(height: 24)
                .padding(.vertical, 4)

            HStack {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .standard))")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(tips).font(.caption)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 6)
    }
}

struct Sparkline: View {
    let values: [Double]
    var body: some View {
        GeometryReader { geo in
            let maxVal = max(values.max() ?? 1, 1)
            let minVal = values.min() ?? 0
            let range = max(maxVal - minVal, 1)
            Path { path in
                for (idx, v) in values.enumerated() {
                    let x = geo.size.width * CGFloat(idx) / CGFloat(max(values.count - 1, 1))
                    let yNorm = (v - minVal) / range
                    let y = geo.size.height * (1 - CGFloat(yNorm))
                    if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
    }
}
