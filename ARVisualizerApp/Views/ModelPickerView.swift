//
//  ModelPickerView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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

