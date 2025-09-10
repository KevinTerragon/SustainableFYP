//
//  OverlayLabelEntity.swift
//  SustainableFYP
//
//  Created by SIT on 10/9/25.
//

import RealityKit

final class OverlayLabelEntity: Entity, HasModel {
    private var text: String = ""

    func configure(text: String) {
        self.text = text
        let mesh = MeshResource.generateText(text,
                                             extrusionDepth: 0.004,
                                             font: .systemFont(ofSize: 0.06),
                                             containerFrame: .zero,
                                             alignment: .left,
                                             lineBreakMode: .byWordWrapping)
        let material = UnlitMaterial(color: .white)
        self.model = ModelComponent(mesh: mesh, materials: [material])
        self.components.set(BillboardComponent())
    }

    func update(text: String) {
        guard text != self.text else { return }
        configure(text: text)
    }
}
