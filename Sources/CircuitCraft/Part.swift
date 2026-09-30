//
//  Part.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

// MARK: - 模型定义
struct Part: Identifiable {
    let id = UUID()
    let imageName: String
    var position: CGPoint
    // 对于 input signal 和 output signal 零件，signal 保存二进制值，默认 0
    var signal: Int = 0
}
