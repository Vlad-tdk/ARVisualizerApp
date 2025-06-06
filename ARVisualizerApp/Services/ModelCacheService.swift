//
//  ModelCacheService.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI
import RealityFoundation

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

