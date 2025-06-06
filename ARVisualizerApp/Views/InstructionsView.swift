//
//  InstructionsView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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

