//
//  SelectedModelView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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

