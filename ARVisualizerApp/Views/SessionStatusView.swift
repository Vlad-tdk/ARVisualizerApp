//
//  SessionStatusView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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
                .onChange(of: isRunning) {_, newValue in
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

