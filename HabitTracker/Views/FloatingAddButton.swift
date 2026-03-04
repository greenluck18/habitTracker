//
//  FloatingAddButton.swift
//  HabitTracker
//
//  Created by Claude AI on 02/27/2026.
//

import SwiftUI

/// Floating Action Button for adding new habits
/// Premium, minimal design with subtle animations and haptics
struct FloatingAddButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HabitTheme.Haptics.selection()
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(HabitTheme.Colors.brand)
                .clipShape(Circle())
                .shadow(color: HabitTheme.Colors.brand.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Add new habit")
        .accessibilityHint("Opens modal to create a new habit")
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingAddButton {
                    print("Add tapped")
                }
                .padding()
            }
        }
    }
}
