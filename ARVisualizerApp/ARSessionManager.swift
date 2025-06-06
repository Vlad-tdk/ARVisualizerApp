//
//  ARSessionManager.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI
import ARKit
import RealityKit
import Combine
import AVFoundation

// MARK: - AR Session Manager (ИСПРАВЛЕННОЕ УПРАВЛЕНИЕ МОДЕЛЯМИ)
@MainActor
class ARSessionManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var sessionState: ARSessionState = .notStarted
    @Published var placedModels: [PlacedModel] = []
    @Published var selectedModel: ARModel?
    @Published var selectedPlacedModel: PlacedModel?
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var detectedPlanes: [ARPlaneAnchor] = []
    @Published var showingModelControls = false
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private var arView: ARView?
    private var cancellables = Set<AnyCancellable>()
    private let modelCache = ModelCacheService()
    private var lastTapTime: Date?
    private var lastLongPressTime: Date?
    
    enum ARSessionState {
        case notStarted
        case starting
        case running
        case paused
        case failed(String)
    }
    
    override init() {
        super.init()
    }
    
    // MARK: - Setup Methods
    func setupARView(_ arView: ARView) {
        print("🔗 Подключение к уже работающему ARView...")
        self.arView = arView
        arView.session.delegate = self
        
        setupGestures()
        
        // Включаем детекцию плоскостей через небольшую задержку
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.enablePlaneDetection()
        }
        
        // Проверяем статус
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.waitForFirstFrame()
        }
    }
    
    private func waitForFirstFrame() {
        guard let arView = arView else { return }
        
        if arView.session.currentFrame != nil {
            sessionState = .running
            isSessionRunning = true
            print("✅ AR сессия работает, frame получен")
        } else {
            print("⏳ Ждем первый frame...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.waitForFirstFrame()
            }
        }
    }
    
    private func enablePlaneDetection() {
        guard let arView = arView else { return }
        
        print("📍 Включение детекции плоскостей...")
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .none
        configuration.isLightEstimationEnabled = false
        configuration.providesAudioData = false
        configuration.isAutoFocusEnabled = true
        
        if let currentFormat = arView.session.configuration?.videoFormat {
            configuration.videoFormat = currentFormat
        }
        
        if #available(iOS 14.0, *) {
            configuration.sceneReconstruction = []
        }
        
        if #available(iOS 13.0, *) {
            configuration.frameSemantics = []
        }
        
        arView.session.run(configuration, options: [])
    }
    
    // MARK: - Gesture Handling
    private func setupGestures() {
        guard let arView = arView else { return }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.8
        
        arView.addGestureRecognizer(tapGesture)
        arView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView,
              shouldProcessGesture(&lastTapTime) else { return }
        
        let location = gesture.location(in: arView)
        
        // Проверяем попадание в существующую модель
        if let hitEntity = arView.entity(at: location),
           let placedModel = findPlacedModel(for: hitEntity) {
            selectModel(placedModel)
            return
        }
        
        // Размещение новой модели
        guard let selectedModel = selectedModel else {
            showAlert("Сначала выберите модель для размещения")
            return
        }
        
        guard placedModels.count < 8 else {
            showAlert("Достигнут максимум моделей (8)")
            return
        }
        
        placeModelAtLocation(selectedModel, at: location)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let arView = arView,
              shouldProcessGesture(&lastLongPressTime) else { return }
        
        let location = gesture.location(in: arView)
        
        if let hitEntity = arView.entity(at: location),
           let placedModel = findPlacedModel(for: hitEntity) {
            deleteModel(placedModel)
        }
    }
    
    private func shouldProcessGesture(_ lastGestureTime: inout Date?) -> Bool {
        let now = Date()
        if let lastTime = lastGestureTime,
           now.timeIntervalSince(lastTime) < 0.3 {
            return false
        }
        lastGestureTime = now
        return true
    }
    
    private func findPlacedModel(for entity: Entity) -> PlacedModel? {
        return placedModels.first { placedModel in
            placedModel.entity == entity || placedModel.entity?.children.contains(entity) == true
        }
    }
    
    // MARK: - Model Management
    private func placeModelAtLocation(_ model: ARModel, at location: CGPoint) {
        guard let arView = arView else { return }
        
        // Проверяем что AR сессия работает
        guard arView.session.currentFrame != nil else {
            showAlert("AR сессия не готова. Подождите...")
            return
        }
        
        // Пробуем разные типы raycast
        var raycastResults: [ARRaycastResult] = []
        
        // 1. Existing planes
        if let existingQuery = arView.makeRaycastQuery(
            from: location,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        ) {
            raycastResults = arView.session.raycast(existingQuery)
        }
        
        // 2. Estimated planes
        if raycastResults.isEmpty,
           let estimatedQuery = arView.makeRaycastQuery(
            from: location,
            allowing: .estimatedPlane,
            alignment: .horizontal
           ) {
            raycastResults = arView.session.raycast(estimatedQuery)
        }
        
        // 3. Any surfaces
        if raycastResults.isEmpty,
           let anyQuery = arView.makeRaycastQuery(
            from: location,
            allowing: .estimatedPlane,
            alignment: .any
           ) {
            raycastResults = arView.session.raycast(anyQuery)
        }
        
        if let firstResult = raycastResults.first {
            print("✅ Raycast успешен! Позиция: \(firstResult.worldTransform.translation)")
            
            Task {
                await placeModel(model, at: firstResult.worldTransform)
            }
        } else {
            showAlert("Поверхность не обнаружена. Медленно двигайте устройство.")
        }
    }
    
    func placeModel(_ model: ARModel, at transform: simd_float4x4) async {
        guard let arView = arView else { return }
        
        isLoading = true
        
        do {
            // ИСПРАВЛЕНО: Правильное создание anchor
            let anchor = AnchorEntity()
            anchor.transform = Transform(matrix: transform)
            
            let entity = await modelCache.getModel(for: model)
            
            // ИСПРАВЛЕНО: Entity в identity
            entity.transform = .identity
            
            // ИСПРАВЛЕНО: Применяем автомасштаб напрямую к entity
            let bounds = entity.visualBounds(relativeTo: nil)
            let maxDimension = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            let targetSize: Float = 0.3
            let scaleFactor = targetSize / maxDimension
            entity.scale = SIMD3<Float>(repeating: scaleFactor)
            
            // Генерируем коллизии
            entity.generateCollisionShapes(recursive: false)
            
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            
            let placedModel = PlacedModel(
                model: model,
                entity: entity,
                anchor: anchor,
                transform: entity.transform
            )
            
            // ИСПРАВЛЕНО: Сохраняем реальные значения для контроллов
            placedModel.currentScale = scaleFactor
            placedModel.position = entity.transform.translation
            
            await MainActor.run {
                self.placedModels.append(placedModel)
                self.isLoading = false
                
                if model.isAnimated {
                    self.addAnimation(to: entity)
                }
                
                print("✅ Модель размещена: \(model.name) с масштабом: \(scaleFactor)")
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.showAlert("Ошибка размещения модели: \(error.localizedDescription)")
            }
        }
    }
    
    private func selectModel(_ model: PlacedModel) {
        selectedPlacedModel?.isSelected = false
        selectedPlacedModel = model
        model.isSelected = true
        showingModelControls = true
        print("🎯 Выбрана модель: \(model.model.name)")
    }
    
    func deleteModel(_ modelToDelete: PlacedModel) {
        guard let arView = arView else { return }
        
        if let anchor = modelToDelete.anchor {
            arView.scene.removeAnchor(anchor)
        }
        
        placedModels.removeAll { $0.id == modelToDelete.id }
        
        if selectedPlacedModel?.id == modelToDelete.id {
            selectedPlacedModel = nil
            showingModelControls = false
        }
        
        print("🗑️ Модель удалена: \(modelToDelete.model.name)")
    }
    
    func clearAllModels() {
        guard let arView = arView else { return }
        
        for placedModel in placedModels {
            if let anchor = placedModel.anchor {
                arView.scene.removeAnchor(anchor)
            }
        }
        placedModels.removeAll()
        selectedPlacedModel = nil
        showingModelControls = false
        
        print("🧹 Все модели удалены")
    }
    
    // MARK: - Model Control Methods (ИСПРАВЛЕНО)
    func updateModelScale(_ placedModel: PlacedModel, scale: Float) {
        guard let entity = placedModel.entity,
              let index = placedModels.firstIndex(where: { $0.id == placedModel.id }) else {
            print("❌ Не найден entity или индекс для масштабирования")
            return
        }
        
        let clampedScale = max(0.1, min(5.0, scale))
        let newScale = SIMD3<Float>(clampedScale, clampedScale, clampedScale)
        
        print("🔧 Обновление масштаба: \(entity.scale) -> \(newScale)")
        
        entity.scale = newScale
        placedModels[index].currentScale = clampedScale
        placedModels[index].transform.scale = newScale
        
        print("✅ Масштаб обновлен: \(entity.scale)")
    }
    
    func updateModelPosition(_ placedModel: PlacedModel, position: SIMD3<Float>) {
        guard let entity = placedModel.entity,
              let index = placedModels.firstIndex(where: { $0.id == placedModel.id }) else {
            print("❌ Не найден entity или индекс для позиционирования")
            return
        }
        
        let clampedPosition = SIMD3<Float>(
            max(-3.0, min(3.0, position.x)),
            max(-2.0, min(3.0, position.y)),
            max(-3.0, min(3.0, position.z))
        )
        
        print("🔧 Обновление позиции: \(entity.transform.translation) -> \(clampedPosition)")
        
        entity.transform.translation = clampedPosition
        placedModels[index].position = clampedPosition
        placedModels[index].transform.translation = clampedPosition
        
        print("✅ Позиция обновлена: \(entity.transform.translation)")
    }
    
    func rotateModel(_ placedModel: PlacedModel, angle: Float) {
        guard let entity = placedModel.entity,
              let index = placedModels.firstIndex(where: { $0.id == placedModel.id }) else {
            print("❌ Не найден entity или индекс для поворота")
            return
        }
        
        let rotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
        
        print("🔧 Обновление поворота: угол \(angle * 180 / .pi)°")
        
        entity.transform.rotation = rotation
        placedModels[index].transform.rotation = rotation
        
        print("✅ Поворот обновлен")
    }
    
    // MARK: - Session Control
    func pauseSession() {
        guard isSessionRunning else { return }
        
        arView?.session.pause()
        isSessionRunning = false
        sessionState = .paused
        
        print("⏸️ AR сессия приостановлена")
    }
    
    func resumeSession() {
        guard let arView = arView, !isSessionRunning else { return }
        
        print("▶️ Возобновление AR сессии...")
        
        if let currentConfig = arView.session.configuration {
            arView.session.run(currentConfig)
        } else {
            enablePlaneDetection()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.arView?.session.currentFrame != nil {
                self.isSessionRunning = true
                self.sessionState = .running
                print("✅ AR сессия возобновлена")
            }
        }
    }
    
    // MARK: - Animation
    private func addAnimation(to entity: ModelEntity) {
        let rotationTransform = Transform(
            scale: entity.transform.scale,
            rotation: simd_quatf(angle: .pi * 2, axis: SIMD3<Float>(0, 1, 0)),
            translation: entity.transform.translation
        )
        
        let rotationAnimation = FromToByAnimation(
            name: "rotation",
            from: entity.transform,
            to: rotationTransform,
            duration: 4.0,
            timing: .linear,
            isAdditive: false,
            repeatMode: .repeat
        )
        
        do {
            let animationResource = try AnimationResource.generate(with: rotationAnimation)
            entity.playAnimation(animationResource)
            print("🎬 Анимация добавлена к модели")
        } catch {
            print("❌ Ошибка создания анимации: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
        print("⚠️ Алерт: \(message)")
    }
}

// MARK: - AR Session Delegate
extension ARSessionManager: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR Session Error: \(error.localizedDescription)")
        
        Task { @MainActor in
            self.sessionState = .failed(error.localizedDescription)
            self.showAlert("AR ошибка: \(error.localizedDescription)")
        }
    }
    
    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        Task { @MainActor in
            self.trackingState = camera.trackingState
            
            switch camera.trackingState {
            case .normal:
                print("📍 Отслеживание: Нормальное")
            case .notAvailable:
                print("📍 Отслеживание: Недоступно")
            case .limited(let reason):
                print("📍 Отслеживание: Ограниченное - \(reason)")
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let planeAnchors = anchors.compactMap { $0 as? ARPlaneAnchor }
        guard !planeAnchors.isEmpty else { return }
        
        Task { @MainActor in
            let horizontalPlanes = planeAnchors.filter { $0.alignment == .horizontal }
            self.detectedPlanes.append(contentsOf: horizontalPlanes)
            print("📍 Добавлено горизонтальных плоскостей: \(horizontalPlanes.count)")
        }
    }
    
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let planeAnchors = anchors.compactMap { $0 as? ARPlaneAnchor }
        guard !planeAnchors.isEmpty else { return }
        
        Task { @MainActor in
            for planeAnchor in planeAnchors where planeAnchor.alignment == .horizontal {
                if let index = self.detectedPlanes.firstIndex(where: { $0.identifier == planeAnchor.identifier }) {
                    self.detectedPlanes[index] = planeAnchor
                }
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        let planeAnchors = anchors.compactMap { $0 as? ARPlaneAnchor }
        guard !planeAnchors.isEmpty else { return }
        
        Task { @MainActor in
            for planeAnchor in planeAnchors {
                self.detectedPlanes.removeAll { $0.identifier == planeAnchor.identifier }
            }
        }
    }
}
// MARK: - Extensions для дебага
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
