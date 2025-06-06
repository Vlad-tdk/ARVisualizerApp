//
//  ContentView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 5. 6. 2025..
//

import SwiftUI
import ARKit
import RealityKit
import Combine
import AVFoundation

// MARK: - App Configuration
// MARK: - App Configuration (ИСПРАВЛЕНО)
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

class PlacedModel: ObservableObject, Identifiable {
    let id = UUID()
    let model: ARModel
    weak var entity: ModelEntity?
    weak var anchor: AnchorEntity?
    @Published var transform: Transform
    @Published var currentScale: Float
    @Published var position: SIMD3<Float>
    @Published var isSelected: Bool = false
    
    init(model: ARModel, entity: ModelEntity, anchor: AnchorEntity, transform: Transform) {
        self.model = model
        self.entity = entity
        self.anchor = anchor
        self.transform = transform
        self.currentScale = model.scale
        self.position = transform.translation
    }
    
    deinit {
        print("🗑️ PlacedModel освобожден: \(model.name)")
    }
}

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

// MARK: - Model Cache Service
@MainActor
class ModelCacheService: ObservableObject {
    private var cachedEntities: [String: ModelEntity] = [:]
    private let modelFactory = ProceduralModelFactory()
    
    func getModel(for arModel: ARModel) async -> ModelEntity {
        if let cached = cachedEntities[arModel.fileName] {
            print("📱 Модель из кэша: \(arModel.fileName)")
            return cached.clone(recursive: true)
        }
        
        let entity = await loadModelEntity(for: arModel)
        manageCacheSize()
        cachedEntities[arModel.fileName] = entity
        print("💾 Модель добавлена в кэш: \(arModel.fileName)")
        return entity.clone(recursive: true)
    }
    
    private func manageCacheSize() {
        guard cachedEntities.count >= AppConfig.maxCacheSize else { return }
        
        let firstKey = cachedEntities.keys.first!
        cachedEntities.removeValue(forKey: firstKey)
        print("🧹 Очистка кэша: удален \(firstKey)")
    }
    
    private func loadModelEntity(for model: ARModel) async -> ModelEntity {
        if let modelURL = Bundle.main.url(forResource: model.fileName.replacingOccurrences(of: ".usdz", with: ""), withExtension: "usdz") {
            do {
                let entity = try await ModelEntity(contentsOf: modelURL)
                print("✅ Успешно загружена модель: \(model.fileName)")
                return entity
            } catch {
                print("❌ Ошибка загрузки модели \(model.fileName): \(error)")
            }
        }
        
        print("🔧 Создаем процедурную модель для категории: \(model.category.rawValue)")
        return modelFactory.createModel(for: model.category)
    }
    
    func clearCache() {
        cachedEntities.removeAll()
        print("🧹 Кэш моделей очищен")
    }
}

// MARK: - Procedural Model Factory
struct ProceduralModelFactory {
    func createModel(for category: ARModel.ModelCategory) -> ModelEntity {
        switch category {
        case .furniture: return createChair()
        case .electronics: return createLaptop()
        case .decorations: return createStar()
        case .vehicles: return createCar()
        case .architecture: return createBuilding()
        }
    }
    
    private func createChair() -> ModelEntity {
        let seat = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.5, 0.05, 0.5)))
        seat.model?.materials = [SimpleMaterial(color: .brown, isMetallic: false)]
        
        let backrest = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.5, 0.6, 0.05)))
        backrest.position = SIMD3<Float>(0, 0.325, 0.225)
        backrest.model?.materials = [SimpleMaterial(color: .brown, isMetallic: false)]
        
        seat.addChild(backrest)
        addChairLegs(to: seat)
        return seat
    }
    
    private func addChairLegs(to seat: ModelEntity) {
        let legPositions = [
            SIMD3<Float>(0.2, -0.225, 0.2),
            SIMD3<Float>(-0.2, -0.225, 0.2),
            SIMD3<Float>(0.2, -0.225, -0.2),
            SIMD3<Float>(-0.2, -0.225, -0.2)
        ]
        
        for legPosition in legPositions {
            let leg = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.05, 0.4, 0.05)))
            leg.position = legPosition
            leg.model?.materials = [SimpleMaterial(color: .brown, isMetallic: false)]
            seat.addChild(leg)
        }
    }
    
    private func createLaptop() -> ModelEntity {
        let base = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.3, 0.02, 0.2)))
        base.model?.materials = [SimpleMaterial(color: .gray, isMetallic: true)]
        
        let screen = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.3, 0.2, 0.01)))
        screen.position = SIMD3<Float>(0, 0.1, -0.095)
        screen.orientation = simd_quatf(angle: -0.3, axis: SIMD3<Float>(1, 0, 0))
        screen.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
        
        base.addChild(screen)
        return base
    }
    
    private func createStar() -> ModelEntity {
        let star = ModelEntity(mesh: .generateSphere(radius: 0.1))
        star.model?.materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
        return star
    }
    
    private func createCar() -> ModelEntity {
        let body = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.4, 0.1, 0.15)))
        body.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
        addWheels(to: body)
        return body
    }
    
    private func addWheels(to body: ModelEntity) {
        let wheelPositions = [
            SIMD3<Float>(0.15, -0.075, 0.1),
            SIMD3<Float>(-0.15, -0.075, 0.1),
            SIMD3<Float>(0.15, -0.075, -0.1),
            SIMD3<Float>(-0.15, -0.075, -0.1)
        ]
        
        for wheelPosition in wheelPositions {
            let wheel = ModelEntity(mesh: .generateCylinder(height: 0.05, radius: 0.04))
            wheel.position = wheelPosition
            wheel.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
            body.addChild(wheel)
        }
    }
    
    private func createBuilding() -> ModelEntity {
        let building = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.3, 0.8, 0.3)))
        building.model?.materials = [SimpleMaterial(color: .gray, isMetallic: false)]
        addWindows(to: building)
        return building
    }
    
    private func addWindows(to building: ModelEntity) {
        for i in 0..<3 {
            for j in 0..<3 {
                let window = ModelEntity(mesh: .generateBox(size: SIMD3<Float>(0.05, 0.08, 0.01)))
                window.position = SIMD3<Float>(
                    -0.1 + Float(j) * 0.1,
                     -0.2 + Float(i) * 0.2,
                     0.151
                )
                window.model?.materials = [SimpleMaterial(color: .cyan, isMetallic: false)]
                building.addChild(window)
            }
        }
    }
}

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
            self?.handleBatteryStateChange()
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


// MARK: - Model Data Service
@MainActor
class ModelDataService: ObservableObject {
    @Published var models: [ARModel] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadModels() async {
        guard models.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            
            await MainActor.run {
                self.models = self.createSampleModels()
                self.isLoading = false
                print("📦 Модели загружены: \(self.models.count)")
            }
        } catch {
            await MainActor.run {
                self.error = "Ошибка загрузки моделей"
                self.isLoading = false
            }
        }
    }
    
    func reloadModels() async {
        models.removeAll()
        await loadModels()
    }
    
    private func createSampleModels() -> [ARModel] {
        return [
            ARModel(
                name: "Деревянный стул",
                fileName: "chair.usdz",
                category: .furniture,
                description: "Классический деревянный стул",
                previewImage: "chair_preview",
                scale: 0.8,
                isAnimated: false
            ),
            ARModel(
                name: "Современный ноутбук",
                fileName: "laptop.usdz",
                category: .electronics,
                description: "Современный ноутбук",
                previewImage: "laptop_preview",
                scale: 0.5,
                isAnimated: false
            ),
            ARModel(
                name: "Золотая звезда",
                fileName: "star.usdz",
                category: .decorations,
                description: "Мерцающая звезда",
                previewImage: "star_preview",
                scale: 0.3,
                isAnimated: true
            ),
            ARModel(
                name: "Спортивная машина",
                fileName: "car.usdz",
                category: .vehicles,
                description: "Модель спортивной машины",
                previewImage: "car_preview",
                scale: 0.6,
                isAnimated: false
            ),
            ARModel(
                name: "Офисное здание",
                fileName: "building.usdz",
                category: .architecture,
                description: "Современное офисное здание",
                previewImage: "building_preview",
                scale: 0.2,
                isAnimated: false
            ),
            ARModel(
                name: "Audi",
                fileName: "Audi.usdz",
                category: .vehicles,
                description: "3D модель Audi",
                previewImage: "audi_preview",
                scale: 0.05,
                isAnimated: false
            ),
            ARModel(
                name: "Скульптура Путти",
                fileName: "Putti_Gruppe.usdz",
                category: .architecture,
                description: "Скульптура Putti",
                previewImage: "putti_preview",
                scale: 0.3,
                isAnimated: false
            )
        ]
    }
}

import SwiftUI
import ARKit
import RealityKit

// MARK: - AR View Container (ИСПРАВЛЕНИЕ ОТОБРАЖЕНИЯ КАМЕРЫ)
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var sessionManager: ARSessionManager
    
    func makeUIView(context: Context) -> ARView {
        print("🚀 Создание ARView с отображением камеры...")
        
        // Создаем ARView БЕЗ автоматической конфигурации
        let arView = ARView(frame: .zero)
        
        // КРИТИЧНО: Полностью отключаем автоматическую конфигурацию
        arView.automaticallyConfigureSession = false
        
        // Убираем проблемные опции, НО ОСТАВЛЯЕМ КАМЕРУ
        arView.debugOptions = []
        
        // ВАЖНО: НЕ ОТКЛЮЧАЕМ background - это убирает камеру!
        // arView.environment.background = .color(.clear) // ЭТО УБИРАЛО КАМЕРУ
        
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
        
        // Создаем МИНИМАЛЬНУЮ конфигурацию
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
            print("📹 Используется видеоформат: \(simpleFormat.imageResolution)")
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
        
        print("✅ Базовая AR сессия с камерой запущена")
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Ничего не делаем в updateUIView чтобы не создавать конфликты
    }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        print("🛑 Корректное освобождение ARView...")
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }
}
// MARK: - UI Components

// Loading Overlay
struct LoadingOverlay: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(Color.white, lineWidth: 4)
                            .rotationEffect(.degrees(rotation))
                    )
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                Text("Загрузка моделей...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

// Instructions View
struct InstructionsView: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Как использовать AR Визуализатор:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        instructionRow("1.", "Медленно двигайте устройство")
                        instructionRow("2.", "Наведите на плоские поверхности")
                        instructionRow("3.", "Дождитесь обнаружения плоскости")
                        instructionRow("4.", "Выберите модель для размещения")
                        instructionRow("5.", "Коснитесь обнаруженной поверхности")
                        instructionRow("6.", "Удерживайте для удаления модели")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(AppConfig.cardCornerRadius)
        .shadow(radius: 10)
    }
    
    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(number)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

// Top Bar View
struct TopBarView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack {
            SessionStatusView(sessionManager: sessionManager)
            
            Spacer()
            
            HStack(spacing: 12) {
                if !sessionManager.placedModels.isEmpty {
                    ModelCountView(count: sessionManager.placedModels.count)
                }
                
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
            }
        }
    }
}

// Session Status View
struct SessionStatusView: View {
    @ObservedObject var sessionManager: ARSessionManager
    @State private var animationRunning = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(animationRunning && isRunning ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animationRunning)
                .onAppear {
                    if isRunning {
                        animationRunning = true
                    }
                }
                .onChange(of: isRunning) { newValue in
                    animationRunning = newValue
                }
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    
    private var isRunning: Bool {
        if case .running = sessionManager.sessionState {
            return true
        }
        return false
    }
    
    private var statusColor: Color {
        switch sessionManager.sessionState {
        case .running: return .green
        case .starting: return .yellow
        case .paused: return .orange
        case .failed, .notStarted: return .red
        }
    }
    
    private var statusText: String {
        switch sessionManager.sessionState {
        case .running: return "AR Активен"
        case .starting: return "Запуск..."
        case .paused: return "Пауза"
        case .failed: return "Ошибка"
        case .notStarted: return "Не запущен"
        }
    }
}

// Model Count View
struct ModelCountView: View {
    let count: Int
    
    var body: some View {
        Text("\(count) моделей")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

// Bottom Controls View
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

// Selected Model View
struct SelectedModelView: View {
    let model: ARModel
    @ObservedObject var sessionManager: ARSessionManager
    
    var body: some View {
        HStack {
            Image(systemName: model.category.icon)
                .font(.title2)
                .foregroundColor(model.category.color)
                .scaleEffect(1.1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Коснитесь поверхности для размещения")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sessionManager.selectedModel = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .cornerRadius(AppConfig.cardCornerRadius)
        .shadow(radius: 5)
    }
}

// Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 60)
            .background(color.opacity(isPressed ? 0.6 : 0.8))
            .cornerRadius(AppConfig.cardCornerRadius)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Model Picker Views

// Model Picker View
struct ModelPickerView: View {
    let models: [ARModel]
    @Binding var selectedCategory: ARModel.ModelCategory?
    @ObservedObject var sessionManager: ARSessionManager
    @Environment(\.dismiss) private var dismiss
    
    private var filteredModels: [ARModel] {
        if let category = selectedCategory {
            return models.filter { $0.category == category }
        }
        return models
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                CategoryPickerView(selectedCategory: $selectedCategory)
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppConfig.gridSpacing) {
                        ForEach(filteredModels) { model in
                            ModelCardView(model: model) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    sessionManager.selectedModel = model
                                }
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Выбор модели")
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
}

// Category Picker View
struct CategoryPickerView: View {
    @Binding var selectedCategory: ARModel.ModelCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "Все",
                    icon: "square.grid.2x2",
                    color: .gray,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(ARModel.ModelCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

// Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .shadow(radius: isSelected ? 2 : 0)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Model Card View
struct ModelCardView: View {
    let model: ARModel
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(model.category.color.opacity(0.2))
                        .frame(height: 120)
                    
                    Group {
                        if UIImage(named: model.previewImage) != nil {
                            Image(model.previewImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                                .cornerRadius(8)
                        } else {
                            Image(systemName: model.category.icon)
                                .font(.system(size: 40))
                                .foregroundColor(model.category.color)
                        }
                    }
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                
                VStack(spacing: 6) {
                    Text(model.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    HStack {
                        if model.isAnimated {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        
                        Text(model.category.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(model.category.color.opacity(0.2))
                            .foregroundColor(model.category.color)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(AppConfig.cardCornerRadius)
            .shadow(radius: isPressed ? 5 : 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
            // Заголовок
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
            
            // Быстрые действия
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

// MARK: - Control Components

// Control Slider View
struct ControlSliderView: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let format: String
    let color: Color
    var valueFormatter: ((Float) -> Float)?
    let onChange: (Float) -> Void
    
    init(title: String, value: Binding<Float>, range: ClosedRange<Float>, step: Float, format: String, color: Color, valueFormatter: ((Float) -> Float)? = nil, onChange: @escaping (Float) -> Void) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
        self.color = color
        self.valueFormatter = valueFormatter
        self.onChange = onChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: format, valueFormatter?(value) ?? value))
                    .font(.caption)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }
            
            HStack {
                Button("-") {
                    value = max(range.lowerBound, value - step)
                    onChange(value)
                }
                .foregroundColor(.white)
                .font(.title3)
                
                Slider(value: $value, in: range, step: step)
                    .onChange(of: value) { newValue in
                        onChange(newValue)
                    }
                    .accentColor(color)
                
                Button("+") {
                    value = min(range.upperBound, value + step)
                    onChange(value)
                }
                .foregroundColor(.white)
                .font(.title3)
            }
        }
    }
}

// Mini Slider View
struct MiniSliderView: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let color: Color
    let onChange: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(title): \(String(format: "%.1f", value))")
                .font(.caption2)
                .foregroundColor(.white)
            
            Slider(value: $value, in: range, step: 0.1)
                .onChange(of: value) { newValue in
                    onChange(newValue)
                }
                .accentColor(color)
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

// Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .frame(width: 50, height: 40)
            .background(Color.white.opacity(isPressed ? 0.3 : 0.2))
            .cornerRadius(8)
            .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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

// Settings Helper Views
struct StatisticRow: View {
    let title: String
    let value: String
    var color: Color = .secondary
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(color)
        }
    }
}

struct ActionRow: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(color)
        }
    }
}

import SwiftUI
import ARKit
import AVFoundation

// MARK: - Main Content View (ИСПРАВЛЕНИЕ ДЛЯ КАМЕРЫ)
struct ContentView: View {
    @StateObject private var sessionManager = ARSessionManager()
    @StateObject private var modelService = ModelDataService()
    @State private var showingModelPicker = false
    @State private var selectedCategory: ARModel.ModelCategory?
    @State private var showingInstructions = true
    @State private var showingSettings = false
    @State private var hasRequestedPermissions = false
    
    var body: some View {
        ZStack {
            // AR View ВСЕГДА отображается и должен показывать камеру
            ARViewContainer(sessionManager: sessionManager)
                .ignoresSafeArea()
                .background(Color.black) // Fallback цвет пока камера не запустилась
            
            VStack {
                TopBarView(sessionManager: sessionManager, showingSettings: $showingSettings)
                
                if showingInstructions && sessionManager.placedModels.isEmpty {
                    InstructionsView(isVisible: $showingInstructions)
                        .transition(.opacity)
                }
                
                Spacer()
                
                BottomControlsView(
                    sessionManager: sessionManager,
                    modelService: modelService,
                    showingModelPicker: $showingModelPicker,
                    selectedCategory: $selectedCategory
                )
                
                if sessionManager.showingModelControls,
                   let selectedPlacedModel = sessionManager.selectedPlacedModel {
                    ModelControlsView(
                        placedModel: selectedPlacedModel,
                        sessionManager: sessionManager
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
            
            if modelService.isLoading || sessionManager.isLoading {
                LoadingOverlay()
            }
            
            // Индикатор состояния камеры
            if case .running = sessionManager.sessionState {
                // Камера работает - ничего не показываем
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(getSessionStatusText())
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if !hasRequestedPermissions {
                hasRequestedPermissions = true
                initializeApp()
            }
        }
        .onDisappear {
            sessionManager.pauseSession()
        }
        .sheet(isPresented: $showingModelPicker) {
            ModelPickerView(
                models: modelService.models,
                selectedCategory: $selectedCategory,
                sessionManager: sessionManager
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(sessionManager: sessionManager, modelService: modelService)
        }
        .alert("AR Визуализатор", isPresented: $sessionManager.showingAlert) {
            Button("OK") { }
        } message: {
            Text(sessionManager.alertMessage)
        }
    }
    
    private func getSessionStatusText() -> String {
        switch sessionManager.sessionState {
        case .notStarted:
            return "AR не запущен"
        case .starting:
            return "Запуск AR..."
        case .running:
            return ""
        case .paused:
            return "AR приостановлен"
        case .failed(let error):
            return "Ошибка AR: \(error)"
        }
    }
    
    private func initializeApp() {
        print("🚀 Инициализация приложения...")
        
        // Проверяем поддержку ARKit
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ ARKit не поддерживается")
            sessionManager.sessionState = .failed("ARKit не поддерживается на этом устройстве")
            showARKitNotSupportedAlert()
            return
        }
        
        print("✅ ARKit поддерживается")
        
        // Запрашиваем разрешение камеры
        requestCameraPermission()
    }
    
    private func requestCameraPermission() {
        print("🎥 Проверка разрешения камеры...")
        
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch currentStatus {
        case .authorized:
            print("✅ Разрешение камеры уже предоставлено")
            handleCameraPermissionGranted()
            
        case .notDetermined:
            print("❓ Запрос разрешения камеры...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Разрешение камеры получено")
                        self.handleCameraPermissionGranted()
                    } else {
                        print("❌ Разрешение камеры отклонено")
                        self.handleCameraPermissionDenied()
                    }
                }
            }
            
        case .denied, .restricted:
            print("❌ Разрешение камеры отклонено/ограничено")
            handleCameraPermissionDenied()
            
        @unknown default:
            print("❓ Неизвестный статус разрешения камеры")
            handleCameraPermissionDenied()
        }
    }
    
    private func handleCameraPermissionGranted() {
        print("🎯 Обработка предоставленного разрешения камеры")
        
        // Небольшая задержка для стабильности
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                print("📦 Начинаем загрузку моделей...")
                await self.modelService.loadModels()
                print("📦 Модели загружены, AR готов к работе")
            }
        }
    }
    
    private func handleCameraPermissionDenied() {
        sessionManager.sessionState = .failed("Доступ к камере запрещен")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sessionManager.showingAlert = true
            sessionManager.alertMessage = """
                Для работы AR необходим доступ к камере.
                
                Перейдите в:
                Настройки → Конфиденциальность и безопасность → Камера
                и включите доступ для этого приложения.
                """
        }
    }
    
    private func showARKitNotSupportedAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sessionManager.showingAlert = true
            sessionManager.alertMessage = """
                ARKit не поддерживается на этом устройстве.
                
                Требуется устройство с процессором A9 или новее:
                • iPhone 6s и новее
                • iPad (5-го поколения) и новее
                • iPad Pro (все модели)
                """
        }
    }
}

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
