//
//  ModelControlsView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

// MARK: - Model Controls View
struct ModelControlsView: View {
    let placedModel: PlacedModel
    @ObservedObject var sessionManager: ARSessionManager
    @State private var scaleValue: Float
    @State private var rotationAngle: Float = 0
    @State private var positionX: Float
    @State private var positionY: Float
    @State private var positionZ: Float
    
    init(placedModel: PlacedModel, sessionManager: ARSessionManager) {
        self.placedModel = placedModel
        self.sessionManager = sessionManager
        
        self._scaleValue = State(initialValue: placedModel.currentScale)
        self._positionX = State(initialValue: placedModel.position.x)
        self._positionY = State(initialValue: placedModel.position.y)
        self._positionZ = State(initialValue: placedModel.position.z)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: placedModel.model.category.icon)
                        .foregroundColor(placedModel.model.category.color)
                    
                    Text("Редактирование: \(placedModel.model.name)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button("Готово") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sessionManager.selectedPlacedModel = nil
                        sessionManager.showingModelControls = false
                    }
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                QuickActionButton(icon: "arrow.clockwise", title: "90°") {
                    rotationAngle += .pi / 2
                    sessionManager.rotateModel(placedModel, angle: rotationAngle)
                }
                
                QuickActionButton(icon: "minus.magnifyingglass", title: "0.5x") {
                    scaleValue = max(0.1, scaleValue * 0.5)
                    sessionManager.updateModelScale(placedModel, scale: scaleValue)
                }
                
                QuickActionButton(icon: "plus.magnifyingglass", title: "2x") {
                    scaleValue = min(3.0, scaleValue * 2.0)
                    sessionManager.updateModelScale(placedModel, scale: scaleValue)
                }
                
                QuickActionButton(icon: "arrow.up", title: "Вверх") {
                    positionY += 0.1
                    updatePosition()
                }
            }
            
            // Контроль масштаба
            ControlSliderView(
                title: "Масштаб",
                value: $scaleValue,
                range: 0.1...3.0,
                step: 0.1,
                format: "%.1f",
                color: .blue
            ) { newValue in
                sessionManager.updateModelScale(placedModel, scale: newValue)
            }
            
            // Контроль поворота
            ControlSliderView(
                title: "Поворот",
                value: $rotationAngle,
                range: 0...(.pi * 2),
                step: 0.1,
                format: "%.0f°",
                color: .green,
                valueFormatter: { $0 * 180 / .pi }
            ) { newValue in
                sessionManager.rotateModel(placedModel, angle: newValue)
            }
            
            // Контроль позиции
            VStack(alignment: .leading, spacing: 12) {
                Text("Позиция")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    MiniSliderView(
                        title: "X",
                        value: $positionX,
                        range: -2.0...2.0,
                        color: .red
                    ) { _ in updatePosition() }
                    
                    MiniSliderView(
                        title: "Y",
                        value: $positionY,
                        range: -1.0...1.0,
                        color: .green
                    ) { _ in updatePosition() }
                    
                    MiniSliderView(
                        title: "Z",
                        value: $positionZ,
                        range: -2.0...2.0,
                        color: .blue
                    ) { _ in updatePosition() }
                }
            }
            
            // Кнопки действий
            HStack(spacing: 16) {
                ActionButton(
                    icon: "arrow.counterclockwise",
                    title: "Сброс",
                    color: .gray
                ) {
                    resetToDefaults()
                }
                
                ActionButton(
                    icon: "trash.fill",
                    title: "Удалить",
                    color: .red
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sessionManager.deleteModel(placedModel)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.95))
        .cornerRadius(AppConfig.cardCornerRadius)
        .shadow(radius: 10)
    }
    
    private func updatePosition() {
        let newPosition = SIMD3<Float>(positionX, positionY, positionZ)
        sessionManager.updateModelPosition(placedModel, position: newPosition)
    }
    
    private func resetToDefaults() {
        scaleValue = placedModel.model.scale
        rotationAngle = 0
        let currentPos = placedModel.position
        positionX = currentPos.x
        positionY = currentPos.y
        positionZ = currentPos.z
        
        sessionManager.updateModelScale(placedModel, scale: scaleValue)
        sessionManager.rotateModel(placedModel, angle: rotationAngle)
        updatePosition()
    }
}

