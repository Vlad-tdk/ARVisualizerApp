//
//  StatisticRow.swift
//  ARVisualizerApp
//
//  Created by Vladimir Martemianov on 6. 6. 2025..
//

import SwiftUI

struct StatisticRow: View {
    let title: String
    let value: String
    var color: Color = .secondary
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(color)
        }
    }
}
