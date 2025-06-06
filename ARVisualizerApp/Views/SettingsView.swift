//
//  SettingsView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI
import ARKit

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @ObservedObject var modelService: ModelDataService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Статистика") {
                    StatisticRow(title: "Размещенных моделей", value: "\(sessionManager.placedModels.count)")
                    StatisticRow(title: "Обнаруженных плоскостей", value: "\(sessionManager.detectedPlanes.count)")
                    StatisticRow(title: "Состояние отслеживания", value: trackingStateText, color: trackingStateColor)
                }
                
                Section("Действия") {
                    ActionRow(title: "Очистить все модели", color: .red) {
                        sessionManager.clearAllModels()
                    }
                    
                    ActionRow(title: "Перезагрузить модели", color: .blue) {
                        Task {
                            await modelService.reloadModels()
                        }
                    }
                    
                    ActionRow(title: "Сбросить AR сессию", color: .orange) {
                        sessionManager.pauseSession()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            sessionManager.resumeSession()
                        }
                    }
                }
                
                Section("Информация") {
                    StatisticRow(title: "Версия приложения", value: "1.0.0")
                    StatisticRow(
                        title: "Поддержка ARKit",
                        value: ARWorldTrackingConfiguration.isSupported ? "Да" : "Нет",
                        color: ARWorldTrackingConfiguration.isSupported ? .green : .red
                    )
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var trackingStateText: String {
        switch sessionManager.trackingState {
        case .normal: return "Нормальное"
        case .notAvailable: return "Недоступно"
        case .limited(.excessiveMotion): return "Быстрое движение"
        case .limited(.insufficientFeatures): return "Мало признаков"
        case .limited(.initializing): return "Инициализация"
        case .limited(.relocalizing): return "Повторная локализация"
        case .limited: return "Ограниченное"
        @unknown default: return "Неизвестно"
        }
    }
    
    private var trackingStateColor: Color {
        switch sessionManager.trackingState {
        case .normal: return .green
        case .notAvailable: return .red
        case .limited: return .orange
        @unknown default: return .gray
        }
    }
}

