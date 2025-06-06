//
//  ARError.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation

// MARK: - Error Handling
enum ARError: Error, LocalizedError {
    case modelLoadingFailed(String)
    case sessionInitializationFailed
    case placementFailed
    case cameraPermissionDenied
    case unsupportedDevice
    
    var errorDescription: String? {
        switch self {
        case .modelLoadingFailed(let model):
            return "Не удалось загрузить модель: \(model)"
        case .sessionInitializationFailed:
            return "Не удалось инициализировать AR сессию"
        case .placementFailed:
            return "Не удалось разместить модель"
        case .cameraPermissionDenied:
            return "Доступ к камере запрещен"
        case .unsupportedDevice:
            return "ARKit не поддерживается на этом устройстве"
        }
    }
}
