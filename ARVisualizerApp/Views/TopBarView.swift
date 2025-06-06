//
//  TopBarView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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

