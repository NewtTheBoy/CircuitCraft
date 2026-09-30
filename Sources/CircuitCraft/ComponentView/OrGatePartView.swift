//
//  OrGatePartView.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/17/25.
//

import SwiftUI

struct OrGatePartView: View {
    @Binding var part: Part
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        // Use the same height calculation as in NotGatePartView.
        let height: CGFloat = horizontalSizeClass == .regular ? 80 : 50
        
        ZStack {
            Image(part.imageName)
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
