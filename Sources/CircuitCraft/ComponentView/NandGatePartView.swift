//
//  NandGatePartView.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct NandGatePartView: View {
    @Binding var part: Part
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        // Use the same height calculation as in your other gate views.
        let height: CGFloat = horizontalSizeClass == .regular ? 80 : 50

        ZStack {
            Image(part.imageName) // Expecting asset name "nand gate"
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
