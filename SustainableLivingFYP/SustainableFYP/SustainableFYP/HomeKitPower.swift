//
//  HomeKitPower.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import Foundation
import HomeKit

final class HomeKitPower: NSObject, HMHomeManagerDelegate {
    private let manager = HMHomeManager()
    var onPowerUpdate: ((String, Double?) -> Void)?

    func begin() {
        manager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        // Use the first available home (or provide a picker in your UI)
        guard let home = manager.homes.first else { return }

        for accessory in home.accessories where accessory.category.categoryType == HMAccessoryCategoryTypeOutlet {
            for service in accessory.services {
                for ch in service.characteristics {
                    // Heuristic: float characteristic with a power-like name
                    if ch.metadata?.format == HMCharacteristicMetadataFormatFloat,
                       ch.characteristicType.lowercased().contains("power")
                       || ch.localizedDescription.lowercased().contains("power") {
                        ch.enableNotification(true) { _ in }
                        ch.readValue { [weak self] error in
                            guard error == nil else { return }
                            let watts = ch.value as? Double
                            self?.onPowerUpdate?(accessory.name, watts)
                        }
                    }
                }
            }
        }
    }
}
