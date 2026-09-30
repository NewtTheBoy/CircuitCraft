//
//  LevelClearOverlayView.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/9/25.
//

import SwiftUI

struct LevelClearOverlayView: View {
    // 回调：返回 Home、返回关卡选择、重新开始关卡
    let onHome: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            // 半透明背景覆盖整个屏幕
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // 浮动卡片
            VStack(spacing: 20) {
                Text("Level Clear!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("Congratulations! You've cleared the level.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // 按钮区域：三个按钮并排显示或竖直排列也可以
                HStack(spacing: 20) {
                    Button(action: onHome) {
                        Text("Next Level")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding([.horizontal, .bottom], 20)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(20)
            .frame(maxWidth: 600)
            .shadow(radius: 10)
        }
    }
}
