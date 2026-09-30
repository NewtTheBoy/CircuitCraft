//
//  ChangableOutputView.swift
//  
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

// MARK: - 自定义 ChangableOutputView 视图
struct ChangableOutputView: View {
    @Binding var part: Part
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        // 根据设备大小调整参数
        let height: CGFloat = horizontalSizeClass == .regular ? 80 : 50
        let fontSize: CGFloat = horizontalSizeClass == .regular ? 40 : 25
        let offsetValue: CGFloat = horizontalSizeClass == .regular ? -12 : -6
        
        ZStack {
            // 背景图片，按比例缩放
            Image("output signal")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: height)
            
            // 可点击的信号值，选择 0 或 1
            Menu {
                Button("0") { part.signal = 0 }
                Button("1") { part.signal = 1 }
            } label: {
                Text("\(part.signal)")
                    .font(.system(size: fontSize))
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0)) // 透明背景，与原设计一致
                    .cornerRadius(4)
            }
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
