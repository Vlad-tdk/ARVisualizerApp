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

// MARK: - Main Content View
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
        print("Инициализация приложения...")
        
        // Проверяем поддержку ARKit
        guard ARWorldTrackingConfiguration.isSupported else {
            print("ARKit не поддерживается")
            sessionManager.sessionState = .failed("ARKit не поддерживается на этом устройстве")
            showARKitNotSupportedAlert()
            return
        }
        
        print("ARKit поддерживается")
        
        // Запрашиваем разрешение камеры
        requestCameraPermission()
    }
    
    private func requestCameraPermission() {
        print("🎥 Проверка разрешения камеры...")
        
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch currentStatus {
        case .authorized:
            print("Разрешение камеры уже предоставлено")
            handleCameraPermissionGranted()
            
        case .notDetermined:
            print("Запрос разрешения камеры...")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Разрешение камеры получено")
                        self.handleCameraPermissionGranted()
                    } else {
                        print("Разрешение камеры отклонено")
                        self.handleCameraPermissionDenied()
                    }
                }
            }
            
        case .denied, .restricted:
            print("Разрешение камеры отклонено/ограничено")
            handleCameraPermissionDenied()
            
        @unknown default:
            print("Неизвестный статус разрешения камеры")
            handleCameraPermissionDenied()
        }
    }
    
    private func handleCameraPermissionGranted() {
        print("Обработка предоставленного разрешения камеры")
        
        // Небольшая задержка для стабильности
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                print("Начинаем загрузку моделей...")
                await self.modelService.loadModels()
                print("Модели загружены, AR готов к работе")
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
