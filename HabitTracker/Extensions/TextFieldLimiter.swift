//
//  TextFieldLimiter.swift
//  HabitTracker
//
//  Created by Halyna Mazur on 14.04.2025.
//

import SwiftUI

extension View {
    func limitInputLength(value: Binding<String>, length: Int) -> some View {
        self.onChange(of: value.wrappedValue) { oldValue, newValue in
            if newValue.count > length {
                value.wrappedValue = String(newValue.prefix(length))
            }
        }
    }
}

