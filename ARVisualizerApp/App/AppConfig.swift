//
//  AppConfig.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation

// MARK: - App Configuration
struct AppConfig {
    // UI Constants
    static let cardCornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 50
    static let gridSpacing: CGFloat = 16
    static let animationDuration: Double = 0.3
    
    // AR Constants
    static let modelScale: Float = 0.1
    static let maxDistance: Float = 2.0
    static let maxCacheSize = 8  // Уменьшено для стабильности
    static let maxPlacedModels = 12  // Уменьшено для производительности
    
    // Performance Constants
    static let memoryCleanupInterval: TimeInterval = 60.0
    static let gestureDebounceInterval: TimeInterval = 0.3
    static let sessionStartupDelay: TimeInterval = 0.5
    static let retryDelay: TimeInterval = 1.0
    
    // Session Constants
    static let maxRetryAttempts = 3
    static let sessionCheckDelay: TimeInterval = 1.5
    static let permissionCheckDelay: TimeInterval = 0.3
}
