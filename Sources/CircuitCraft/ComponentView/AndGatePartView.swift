//
//  AndGatePartView.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct AndGatePartView: View {
    @Binding var part: Part
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        // Use the same height calculation as in OrGatePartView.
        let height: CGFloat = horizontalSizeClass == .regular ? 80 : 50
        
        ZStack {
            Image(part.imageName) // Expected asset name: "and gate"
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: PartSizePreferenceKey.self, value: [part.id: geo.size])
            }
        )
    }
}
