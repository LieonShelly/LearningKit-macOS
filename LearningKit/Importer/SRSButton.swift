//
//  SRSButton.swift
//  GammarTeacher
//
//  Created by Renjun Li on 2025/12/19.
//

import SwiftUI

struct SRSButton: View {
    let title: String
    let shortcut: KeyEquivalent
    let color: Color
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(String(describing: shortcut))
                    .font(.caption)
                    .opacity(0.6)
            }
            .frame(width: 80, height: 60)
            .background(color.opacity(isHovering ? 0.2 : 0.1))
            .foregroundStyle(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut, modifiers: [])
        .onHover { isHovering = $0 }
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.spring(duration: 0.2), value: isHovering)
    }
}
