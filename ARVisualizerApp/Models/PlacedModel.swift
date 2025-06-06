//
//  PlacedModel.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation
import RealityFoundation

class PlacedModel: ObservableObject, Identifiable {
    let id = UUID()
    let model: ARModel
    weak var entity: ModelEntity?
    weak var anchor: AnchorEntity?
    @Published var transform: Transform
    @Published var currentScale: Float
    @Published var position: SIMD3<Float>
    @Published var isSelected: Bool = false
    
    init(model: ARModel, entity: ModelEntity, anchor: AnchorEntity, transform: Transform) {
        self.model = model
        self.entity = entity
        self.anchor = anchor
        self.transform = transform
        self.currentScale = model.scale
        self.position = transform.translation
    }
    
    deinit {
        print("PlacedModel освобожден: \(model.name)")
    }
}
