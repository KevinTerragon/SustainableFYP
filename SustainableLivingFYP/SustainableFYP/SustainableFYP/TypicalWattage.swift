//
//  TypicalWattage.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import Foundation

enum TypicalWattage {
    static let table: [String: ClosedRange<Double>] = [
        "kettle": 1500...2200,
        "microwave": 800...1500,
        "fan": 30...70,
        "monitor": 20...60,
        "fridge": 80...150,
        "laptop_charger": 45...100,
        "tv": 70...180
    ]
}
