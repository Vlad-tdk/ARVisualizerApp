//
//  PowerManagementService.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import Foundation
import UIKit

// MARK: - Power Management Service
class PowerManagementService: ObservableObject {
    @Published var isLowPowerMode = false
    private var sessionManager: ARSessionManager?
    
    init() {
        setupBatteryMonitoring()
    }
    
    func configure(with sessionManager: ARSessionManager) {
        self.sessionManager = sessionManager
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleBatteryStateChange()
            }
        }
    }
    @MainActor private func handleBatteryStateChange() {
        let batteryLevel = UIDevice.current.batteryLevel
        let shouldUseLowPower = batteryLevel < 0.2
        
        if shouldUseLowPower != isLowPowerMode {
            isLowPowerMode = shouldUseLowPower
            
        }
    }
    
    deinit {
        UIDevice.current.isBatteryMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }
}
