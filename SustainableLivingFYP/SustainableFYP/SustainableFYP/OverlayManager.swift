//
//  OverlayManager.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import RealityKit
import Foundation
import Observation

@MainActor
@Observable
final class OverlayManager {
    private var label = OverlayLabelEntity()
    private var dashboardAnchor = AnchorEntity()

    private(set) var currentName: String = "Detecting…"
    private(set) var currentWatts: Double = 0
    private(set) var currentCostPerHour: Double = 0
    private(set) var isOn: Bool = false
    private(set) var currentSource: String = "Estimating…"
    private(set) var currentTip: String = ""
    private(set) var recentSamples: [Double] = []
    private(set) var lastUpdated: Date = .now

    var tariffPerKWh: Double = 0.30 {
        didSet { energyEstimator.tariffPerKWh = tariffPerKWh; recalc() }
    }

    private var energyEstimator = EnergyEstimator(tariffPerKWh: 0.30)
    private let sensorManager = SensorDataManager()
    private let guesser = ObjectGuesser()

    private(set) var currentTemperature: Double? = nil // Celsius
    private(set) var currentLumens: Double? = nil     // Lumens

    func start() async {
        sensorManager.onPowerUpdate = { [weak self] name, watts in
            Task { @MainActor in
                guard let self else { return }
                self.currentName = name
                if let w = watts { self.setReading(watts: w, source: "Exact") }
            }
        }
        sensorManager.onTemperatureUpdate = { [weak self] name, temp in
            Task { @MainActor in
                guard let self else { return }
                if self.currentName.lowercased().contains("light") || self.currentName.lowercased().contains("air") || self.currentName.lowercased().contains("ac") {
                    self.currentTemperature = temp
                }
            }
        }
        sensorManager.onLumensUpdate = { [weak self] name, lumens in
            Task { @MainActor in
                guard let self else { return }
                if self.currentName.lowercased().contains("light") {
                    self.currentLumens = lumens
                }
            }
        }
        sensorManager.start()
    }

    func placeOrUpdateLabel(at position: SIMD3<Float>, in root: Entity) {
        if label.parent == nil {
            label.configure(text: "Estimating…")
            let anchor = AnchorEntity(world: .init(position))
            anchor.addChild(label)
            root.addChild(anchor)

            dashboardAnchor = AnchorEntity(world: .init(position + SIMD3<Float>(0, 0.08, 0)))
            root.addChild(dashboardAnchor)
        }
        estimateIfNeeded(scene: root.scene)
        label.update(text: makeDisplayString())
    }

    private func estimateIfNeeded(scene: RealityKit.Scene?) {
        guard currentSource != "Exact" else { return }
        Task { @MainActor in
            let (category, confidence) = await guessCategory(scene: scene)
            let (watts, range) = estimateWatts(for: category)
            currentName = category.capitalized
            currentSource = String(format: "Estimate (%.0f%%)", confidence * 100)
            setReading(watts: watts, source: currentSource)
            currentTip = tipFor(category: category, wattsRange: range)
        }
    }

    private func guessCategory(scene: RealityKit.Scene?) async -> (String, Double) {
        if let guess = await guesser.classify(scene: scene) { return guess }
        return ("device", 0.5)
    }

    private func estimateWatts(for category: String) -> (Double, ClosedRange<Double>) {
        let range = TypicalWattage.table[category] ?? 60...120
        let median = (range.lowerBound + range.upperBound) / 2
        let jitter = Double.random(in: -0.05...0.05) * median
        let estimate = max(range.lowerBound, min(range.upperBound, median + jitter))
        return (estimate, range)
    }

    private func tipFor(category: String, wattsRange: ClosedRange<Double>) -> String {
        switch category {
        case "tv", "monitor": return "Lower brightness or enable energy saver."
        case "kettle": return "Boil only what you need to cut energy."
        case "fridge": return "Check door seal; avoid overfilling for airflow."
        case "microwave": return "Short bursts are most efficient for reheats."
        case "fan": return "Use oscillation; AC may not be needed."
        default: return "Consider a smart plug to get exact readings."
        }
    }

    private func setReading(watts: Double, source: String) {
        currentWatts = max(0, watts.rounded())
        isOn = currentWatts > 2
        currentCostPerHour = energyEstimator.hourlyCost(forWatts: currentWatts)
        recentSamples.append(currentWatts)
        if recentSamples.count > 60 { recentSamples.removeFirst(recentSamples.count - 60) }
        currentSource = source
        lastUpdated = .now
        label.update(text: makeDisplayString())
    }

    private func recalc() {
        guard currentWatts > 0 else { return }
        currentCostPerHour = energyEstimator.hourlyCost(forWatts: currentWatts)
        label.update(text: makeDisplayString())
    }

    private func makeDisplayString() -> String {
        if currentWatts == 0 { return "Estimating…" }
        let hourly = energyEstimator.hourlyCost(forWatts: currentWatts)
        return String(format: "%@\\n~%.0f W • ~$%.3f/hr", currentSource, currentWatts, hourly)
    }
}
