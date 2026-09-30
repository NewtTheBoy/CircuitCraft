//
//  OutputSignalPartView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

struct OutputSignalPartView: View {
    @Binding var part: Part
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        // Adjust values based on the size class.
        let height: CGFloat = horizontalSizeClass == .regular ? 80 : 50
        let fontSize: CGFloat = horizontalSizeClass == .regular ? 40 : 25
        let offsetValue: CGFloat = horizontalSizeClass == .regular ? -12 : -6
        
        ZStack {
            // Background image scaled relative to the computed height.
            Image(part.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
            
            // Display the signal value.
            Text("\(part.signal)")
                .font(.system(size: fontSize))
                .foregroundColor(.black)
                .padding(4)
                .background(Color.white.opacity(0)) // Transparent background.
                .cornerRadius(4)
                .offset(x: offsetValue, y: offsetValue)
                .frame(width: height, height: height, alignment: .bottomTrailing)
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: PartSizePreferenceKey.self, value: [part.id: geo.size])
            }
        )
    }
}


