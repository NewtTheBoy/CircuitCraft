//
//  TrashBinContainerView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

struct TrashBinContainerView: View {
    @Binding var trashBinFrame: CGRect
    var isActive: Bool
    
    var body: some View {
        GeometryReader { geo in
            TrashBinView(isActive: isActive)
                .onAppear {
                    // 获取垃圾桶在“board”坐标系中的frame
                    trashBinFrame = geo.frame(in: .named("board"))
                }
                .onChange(of: geo.frame(in: .named("board"))) { newValue in
                    trashBinFrame = newValue
                }
        }
        .frame(width: 80, height: 80)
        .padding(.leading, 16)
        .padding(.bottom, 16)
    }
}

