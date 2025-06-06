//
//  ControlSliderView.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

// MARK: - Control Components

// Control Slider View
struct ControlSliderView: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let format: String
    let color: Color
    var valueFormatter: ((Float) -> Float)?
    let onChange: (Float) -> Void
    
    init(title: String, value: Binding<Float>, range: ClosedRange<Float>, step: Float, format: String, color: Color, valueFormatter: ((Float) -> Float)? = nil, onChange: @escaping (Float) -> Void) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
        self.color = color
        self.valueFormatter = valueFormatter
        self.onChange = onChange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: format, valueFormatter?(value) ?? value))
                    .font(.caption)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }
            
            HStack {
                Button("-") {
                    value = max(range.lowerBound, value - step)
                    onChange(value)
                }
                .foregroundColor(.white)
                .font(.title3)
                
                Slider(value: $value, in: range, step: step)
                    .onChange(of: value) { _, newValue in
                        onChange(newValue)
                    }
                    .accentColor(color)
                
                Button("+") {
                    value = min(range.upperBound, value + step)
                    onChange(value)
                }
                .foregroundColor(.white)
                .font(.title3)
            }
        }
    }
}
