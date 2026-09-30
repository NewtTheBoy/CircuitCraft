//
//  InputSignalPartView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

// MARK: - 自定义 InputSignalPartView 视图
struct InputSignalPartView: View {
    // Binding so that changes to the signal update the data model.
    @Binding var part: Part
    
    var body: some View {
        ZStack {
            // Background image.
            Image(part.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 50)
            
            // Menu for selecting the signal value (0 or 1), overlaid on the image.
            Menu {
                Button("0") { part.signal = 0 }
                Button("1") { part.signal = 1 }
            } label: {
                Text("\(part.signal)")
                    .font(.system(size: 25))
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0))
                    .cornerRadius(4)
            }
            // Adjust the position of the signal value label inside the image.
            .offset(x: -18, y: -6)
            .frame(width: 50, height: 50, alignment: .bottomTrailing)
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: PartSizePreferenceKey.self, value: [part.id: geo.size])
            }
        )
    }
}

