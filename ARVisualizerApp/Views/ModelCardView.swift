//
//  ModelCardView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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

