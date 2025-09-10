//
//  ObjectGuesser.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import Foundation
import RealityKit

final class ObjectGuesser {
    func classify(scene: RealityKit.Scene?) async -> (String, Double)? {
        let candidates = ["kettle", "microwave", "fan", "monitor", "fridge", "tv", "laptop_charger"]
        guard let pick = candidates.randomElement() else { return nil }
        return (pick, Double.random(in: 0.6...0.9))
    }
}
