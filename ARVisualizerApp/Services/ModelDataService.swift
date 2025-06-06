//
//  ModelDataService.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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
                print("Модели загружены: \(self.models.count)")
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
