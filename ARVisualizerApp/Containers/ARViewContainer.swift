//
//  ARViewContainer.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI
import ARKit
import RealityKit

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: ARSessionManager
    
    func makeUIView(context: Context) -> ARView {
        print("Создание ARView с отображением камеры...")
        
        let arView = ARView(frame: .zero)
        
        // КРИТИЧНО: Полностью отключаем автоматическую конфигурацию
        arView.automaticallyConfigureSession = false
        
        arView.debugOptions = []
        
        // Отключаем только тяжелые функции
        arView.environment.sceneUnderstanding.options = []
        arView.environment.lighting.resource = nil
        
        // Минимальные render опции для производительности
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField]
        
        // НЕМЕДЛЕННО настраиваем и запускаем простейшую конфигурацию
        setupBasicARSession(arView)
        
        // Передаем уже работающий ARView в session manager
        sessionManager.setupARView(arView)
        
        return arView
    }
    
    private func setupBasicARSession(_ arView: ARView) {
        print("⚡ Настройка базовой AR сессии с камерой...")
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []  // Отключаем детекцию плоскостей на старте
        configuration.environmentTexturing = .none
        configuration.isLightEstimationEnabled = false
        configuration.providesAudioData = false
        configuration.isAutoFocusEnabled = true
        
        // Используем самый простой видеоформат
        if let simpleFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: {
            $0.framesPerSecond == 30 && $0.imageResolution.width <= 1280
        }) {
            configuration.videoFormat = simpleFormat
            print("Используется видеоформат: \(simpleFormat.imageResolution)")
        }
        
        // Отключаем все дополнительные функции
        if #available(iOS 14.0, *) {
            configuration.sceneReconstruction = []
        }
        
        if #available(iOS 13.0, *) {
            configuration.frameSemantics = []
        }
        
        // Запускаем БЕЗ reset опций для избежания конфликтов
        arView.session.run(configuration)
        
        print("Базовая AR сессия с камерой запущена")
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Ничего не делаем в updateUIView чтобы не создавать конфликты
    }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        print("Корректное освобождение ARView...")
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }
}
