//
//  ContentView.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import SwiftUI
import RealityKit
import simd

@MainActor
struct ContentView: View {
    @State private var tariffPerKWh: Double = 0.30
    @State private var statusText: String = "Tap to place an energy label"
    @State private var root = Entity()
    @State private var gazeTracker = GazeTracker()
    
    private let overlayManager = OverlayManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Tariff control panel
            HStack {
                Text("Tariff ($/kWh)")
                Slider(value: Binding(
                    get: { tariffPerKWh },
                    set: { tariffPerKWh = $0; overlayManager.tariffPerKWh = $0 }
                ), in: 0.05...0.80)
                Text(String(format: "%.2f", tariffPerKWh)).monospacedDigit()
            }
            .padding(12).background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(statusText).font(.footnote).foregroundStyle(.secondary)
            
            RealityView { content, attachments in
                content.add(root)
                if let dash = attachments.entity(for: "dashboard") {
                    root.addChild(dash)
                }
                if let scene = root.scene {
                    gazeTracker.start(scene: scene)
                }
            } update: { _, _ in
                // per-frame updates if needed
            } attachments: {
                Attachment(id: "dashboard") {
                    DashboardCard(
                        deviceName: overlayManager.currentName,
                        watts: overlayManager.currentWatts,
                        costPerHour: overlayManager.currentCostPerHour,
                        status: overlayManager.isOn ? "On" : "Idle",
                        source: overlayManager.currentSource,
                        lastUpdated: overlayManager.lastUpdated,
                        tips: overlayManager.currentTip,
                        samples: overlayManager.recentSamples
                    )
                }
            }
            .gesture(TapGesture().onEnded {
                placeLabelWithBestEffort()
            })
        }
        .padding(24)
        .task {
            overlayManager.tariffPerKWh = tariffPerKWh
            await overlayManager.start()
            gazeTracker.onLookAt = { _ in }
        }
    }
    
    @inline(__always)
    private func currentCameraPose(in scene: RealityKit.Scene) -> (origin: SIMD3<Float>, forward: SIMD3<Float>)? {
        let query = EntityQuery(where: .has(PerspectiveCameraComponent.self))
        var it = scene.performQuery(query).makeIterator()
        guard let cam = it.next() else {
            return nil
        }
        
        let m = cam.transformMatrix(relativeTo: nil)
        let origin  = SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        let forward = -SIMD3<Float>(m.columns.2.x, m.columns.2.y, m.columns.2.z)
        return (origin, forward)
    }
    
    // Replace your placeLabelWithBestEffort() with this:
    private func placeLabelWithBestEffort() {
        guard let scene = root.scene,
              let (origin, forward) = currentCameraPose(in: scene) else {
            // Last-resort fallback if scene/camera not available yet:
            overlayManager.placeOrUpdateLabel(at: SIMD3<Float>(0, 0, -0.6), in: root)
            statusText = "Placed label in front (fallback)."
            return
        }
        
        // Try a raycast along camera forward
        if let hit = scene.raycast(from: origin,
                                   to: origin + forward * 2.0,
                                   query: .nearest,
                                   mask: .default,
                                   relativeTo: nil).first {
            overlayManager.placeOrUpdateLabel(at: hit.position, in: root)
            statusText = "Placed label on surface."
            return
        }
        
        // No hit → place 0.6 m in front (world space)
        overlayManager.placeOrUpdateLabel(at: origin + forward * 0.6, in: root)
        statusText = "Placed label in front."
    }
}
