//
//  ProceduralModelFactory.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation
import RealityFoundation

// MARK: - Procedural Model Factory
struct ProceduralModelFactory {
    func createModel(for category: ARModel.ModelCategory) -> ModelEntity {
        switch category {
        case .furniture: return createChair()
        case .electronics: return createLaptop()
        case .decorations: return createStar()
        case .vehicles: return createCar()
        case .architecture: return createBuilding()
        }
    }
    
    private func createChair() -> ModelEntity {
        let seat = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.5, 0.05, 0.5)))
        seat.model?.materials = [SimpleMaterial(color: .brown, isMetallic: false)]
        
        let backrest = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.5, 0.6, 0.05)))
        backrest.position = SIMD3<Float>(0, 0.325, 0.225)
        backrest.model?.materials = [SimpleMaterial(color: .brown, isMetallic: false)]
        
        seat.addChild(backrest)
        addChairLegs(to: seat)
        return seat
    }
    
    private func addChairLegs(to seat: ModelEntity) {
        let legPositions = [
            SIMD3<Float>(0.2, -0.225, 0.2),
            SIMD3<Float>(-0.2, -0.225, 0.2),
            SIMD3<Float>(0.2, -0.225, -0.2),
            SIMD3<Float>(-0.2, -0.225, -0.2)
        ]
        
        for legPosition in legPositions {
            let leg = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.05, 0.4, 0.05)))
            leg.position = legPosition
            leg.model?.materials = [SimpleMaterial(color: .brown, isMetallic: false)]
            seat.addChild(leg)
        }
    }
    
    private func createLaptop() -> ModelEntity {
        let base = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.3, 0.02, 0.2)))
        base.model?.materials = [SimpleMaterial(color: .gray, isMetallic: true)]
        
        let screen = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.3, 0.2, 0.01)))
        screen.position = SIMD3<Float>(0, 0.1, -0.095)
        screen.orientation = simd_quatf(angle: -0.3, axis: SIMD3<Float>(1, 0, 0))
        screen.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
        
        base.addChild(screen)
        return base
    }
    
    private func createStar() -> ModelEntity {
        let star = ModelEntity(mesh: .generateSphere(radius: 0.1))
        star.model?.materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
        return star
    }
    
    private func createCar() -> ModelEntity {
        let body = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.4, 0.1, 0.15)))
        body.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
        addWheels(to: body)
        return body
    }
    
    private func addWheels(to body: ModelEntity) {
        let wheelPositions = [
            SIMD3<Float>(0.15, -0.075, 0.1),
            SIMD3<Float>(-0.15, -0.075, 0.1),
            SIMD3<Float>(0.15, -0.075, -0.1),
            SIMD3<Float>(-0.15, -0.075, -0.1)
        ]
        
        for wheelPosition in wheelPositions {
            let wheel = ModelEntity(mesh: .generateCylinder(height: 0.05, radius: 0.04))
            wheel.position = wheelPosition
            wheel.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
            body.addChild(wheel)
        }
    }
    
    private func createBuilding() -> ModelEntity {
        let building = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.3, 0.8, 0.3)))
        building.model?.materials = [SimpleMaterial(color: .gray, isMetallic: false)]
        addWindows(to: building)
        return building
    }
    
    private func addWindows(to building: ModelEntity) {
        for i in 0..<3 {
            for j in 0..<3 {
                let window = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.05, 0.08, 0.01)))
                window.position = SIMD3<Float>(
                    -0.1 + Float(j) * 0.1,
                     -0.2 + Float(i) * 0.2,
                     0.151
                )
                window.model?.materials = [SimpleMaterial(color: .cyan, isMetallic: false)]
                building.addChild(window)
            }
        }
    }
}
