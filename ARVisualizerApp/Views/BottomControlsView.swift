//
//  BottomControlsView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

struct BottomControlsView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @ObservedObject var modelService: ModelDataService
    @Binding var showingModelPicker: Bool
    @Binding var selectedCategory: ARModel.ModelCategory?
    
    var body: some View {
        VStack(spacing: 16) {
            if let selectedModel = sessionManager.selectedModel {
                SelectedModelView(model: selectedModel, sessionManager: sessionManager)
            }
            
            HStack(spacing: 16) {
                ActionButton(
                    icon: "plus.circle.fill",
                    title: "Добавить",
                    color: .blue
                ) {
                    showingModelPicker = true
                }
                
                if !sessionManager.placedModels.isEmpty {
                    ActionButton(
                        icon: "trash.fill",
                        title: "Очистить",
                        color: .red
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            sessionManager.clearAllModels()
                        }
                    }
                }
                
                ActionButton(
                    icon: sessionManager.isSessionRunning ? "pause.fill" : "play.fill",
                    title: sessionManager.isSessionRunning ? "Пауза" : "Продолжить",
                    color: sessionManager.isSessionRunning ? .orange : .green
                ) {
                    if sessionManager.isSessionRunning {
                        sessionManager.pauseSession()
                    } else {
                        sessionManager.resumeSession()
                    }
                }
                
                ActionButton(
                    icon: "camera.rotate",
                    title: "Сброс",
                    color: .purple
                ) {
                    sessionManager.pauseSession()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        sessionManager.resumeSession()
                    }
                }
            }
        }
    }
}

