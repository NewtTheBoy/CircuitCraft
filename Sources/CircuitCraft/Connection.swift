//
//  Connection.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

/// 连接模型，用于记录两个部件之间的连接
struct Connection: Identifiable {
    let id = UUID()
    let source: UUID
    let target: UUID
}
