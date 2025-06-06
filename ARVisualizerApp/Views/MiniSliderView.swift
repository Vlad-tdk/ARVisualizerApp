//
//  MiniSliderView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

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
                .onChange(of: value) {_, newValue in
                    onChange(newValue)
                }
                .accentColor(color)
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }
}

