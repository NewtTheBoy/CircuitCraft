//
//  WireView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

// MARK: - 连线视图 WireView
struct WireView: View {
    let start: CGPoint
    let end: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(Color.red, lineWidth: 2)
    }
}
