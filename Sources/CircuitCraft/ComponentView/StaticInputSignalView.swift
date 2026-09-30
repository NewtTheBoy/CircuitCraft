//
//  StaticInputSignal.swift
//  
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

// MARK: - 自定义 StaticInputSignalView 视图
struct StaticInputSignalView: View {
    @Binding var part: Part // 仍使用 Binding 以保持数据模型一致
    
    var body: some View {
        ZStack {
            // 背景图片
            Image("input signal")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 50)
            
            // 固定显示信号值（无交互）
            Text("\(part.signal)")
                .font(.system(size: 25))
                .foregroundColor(.black)
                .padding(4)
                .background(Color.white.opacity(0)) // 透明背景，与原设计一致
                .cornerRadius(4)
                .offset(x: -18, y: -6) // 与原位置一致
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
