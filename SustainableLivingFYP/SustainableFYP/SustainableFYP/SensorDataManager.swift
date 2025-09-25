// SensorDataManager.swift
// Handles HomeKit/Aqara sensor discovery and value updates

import Foundation

final class SensorDataManager {
    let homeKit = HomeKitPower()
    
    var onPowerUpdate: ((String, Double?) -> Void)?
    var onTemperatureUpdate: ((String, Double?) -> Void)?
    var onLumensUpdate: ((String, Double?) -> Void)?
    
    init() {
        homeKit.onPowerUpdate = { [weak self] name, watts in
            self?.onPowerUpdate?(name, watts)
        }
        homeKit.onTemperatureUpdate = { [weak self] name, temp in
            self?.onTemperatureUpdate?(name, temp)
        }
        homeKit.onLumensUpdate = { [weak self] name, lumens in
            self?.onLumensUpdate?(name, lumens)
        }
    }
    
    func start() {
        homeKit.begin()
    }
}
