//
//  TrashBinView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

struct TrashBinView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var isActive: Bool
    
    var body: some View {
        // Use larger sizes for regular (iPad) and smaller for compact (iPhone)
        let defaultSize: CGFloat = horizontalSizeClass == .regular ? 100 : 60
        let activeSize: CGFloat = horizontalSizeClass == .regular ? 120 : 80
        let iconSize: CGFloat = horizontalSizeClass == .regular ? 30 : 24
        
        ZStack {
            Circle()
                .fill(isActive ? Color.red.opacity(0.3) : Color.gray.opacity(0.3))
                .frame(width: isActive ? activeSize : defaultSize,
                       height: isActive ? activeSize : defaultSize)
            Image(systemName: "trash")
                .font(.system(size: iconSize))
                .foregroundColor(isActive ? .red : .gray)
        }
        .offset(
            x: horizontalSizeClass == .regular ? 20 : 0,
            y: horizontalSizeClass == .regular ? -40 : 0
        )
    }
}

