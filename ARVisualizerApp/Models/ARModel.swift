//
//  ARModel.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation
import RealityKit
import SwiftUICore

// MARK: - Data Models
struct ARModel: Identifiable, Codable, Hashable {
    var id = UUID()
    let name: String
    let fileName: String
    let category: ModelCategory
    let description: String
    let previewImage: String
    let scale: Float
    let isAnimated: Bool
    
    enum ModelCategory: String, CaseIterable, Codable {
        case furniture = "Мебель"
        case electronics = "Электроника"
        case decorations = "Декорации"
        case vehicles = "Транспорт"
        case architecture = "Архитектура"
        
        var icon: String {
            switch self {
            case .furniture: return "sofa.fill"
            case .electronics: return "laptopcomputer"
            case .decorations: return "star.fill"
            case .vehicles: return "car.fill"
            case .architecture: return "building.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .furniture: return .brown
            case .electronics: return .blue
            case .decorations: return .purple
            case .vehicles: return .red
            case .architecture: return .green
            }
        }
    }
}
