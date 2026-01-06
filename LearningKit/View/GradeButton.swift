//
//  GradeButton.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/19.
//

import SwiftUI

struct GradeButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(width: 80, height: 40)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
