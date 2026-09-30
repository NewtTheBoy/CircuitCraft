//
//  View+ConditionalModifier.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }
}
