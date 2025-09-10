//
//  GazeTracker.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import RealityKit
import Combine
import simd
import Foundation

final class GazeTracker {
    private var timer: AnyCancellable?
    private weak var scene: RealityKit.Scene?
    var onLookAt: ((Entity?) -> Void)?

    func start(scene: RealityKit.Scene) {
        self.scene = scene
        timer?.cancel()
        timer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() { timer?.cancel(); timer = nil }

    private func cameraPose() -> (origin: SIMD3<Float>, forward: SIMD3<Float>)? {
        guard let scene else { return nil }
        let query = EntityQuery(where: .has(PerspectiveCameraComponent.self))
        var it = scene.performQuery(query).makeIterator()
        guard let cam = it.next() else { return nil }
        
        let m = cam.transformMatrix(relativeTo: nil)
        let origin  = SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        let forward = -SIMD3<Float>(m.columns.2.x, m.columns.2.y, m.columns.2.z)
        return (origin, forward)
    }

    private func tick() {
        guard let scene,
              let (origin, forward) = cameraPose() else { onLookAt?(nil); return }

        let results = scene.performQuery(EntityQuery(where: .has(ModelComponent.self)))
        var best: (Entity, Float)?
        
        for e in results {
            guard let label = e as? OverlayLabelEntity else { continue }
            let m = label.transformMatrix(relativeTo: nil)
            let epos = SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
            let v = epos - origin
            let dist = length(v)
            guard dist < 1.5 else { continue }
            let cosang = simd_dot(normalize(v), normalize(forward))
            if cosang > 0.96, best == nil || dist < best!.1 { best = (label, dist) }
        }
        onLookAt?(best?.0)
    }
}
