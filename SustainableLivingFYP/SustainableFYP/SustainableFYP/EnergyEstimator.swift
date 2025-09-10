//
//  EnergyEstimator.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import Foundation

struct EnergyEstimator {
    var tariffPerKWh: Double

    func hourlyCost(forWatts w: Double) -> Double {
        let kWh = w / 1000.0
        return kWh * tariffPerKWh
    }

    func sessionCost(watts: Double, minutes: Double) -> Double {
        let kWh = watts * (minutes / 60.0) / 1000.0
        return kWh * tariffPerKWh
    }
}
