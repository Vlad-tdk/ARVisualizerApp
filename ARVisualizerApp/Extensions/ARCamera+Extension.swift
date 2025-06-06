//
//  ARCamera+Extension.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation
import ARKit

extension ARCamera.TrackingState {
    var description: String {
        switch self {
        case .normal:
            return "Нормальное отслеживание"
        case .notAvailable:
            return "Отслеживание недоступно"
        case .limited(.excessiveMotion):
            return "Слишком быстрое движение"
        case .limited(.insufficientFeatures):
            return "Недостаточно признаков"
        case .limited(.initializing):
            return "Инициализация"
        case .limited(.relocalizing):
            return "Повторная локализация"
        case .limited:
            return "Ограниченное отслеживание"
        @unknown default:
            return "Неизвестное состояние"
        }
    }
}
