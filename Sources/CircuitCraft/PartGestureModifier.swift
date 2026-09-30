//
//  PartGestureModifier.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

struct PartGestureModifier: ViewModifier {
    let part: Part
    let allowDrag: Bool
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void
    let onLongPressed: (Part) -> Void

    func body(content: Content) -> some View {
        // 使用 AnyView 统一类型
        let contentWithDrag: AnyView = allowDrag ?
            AnyView(
                content.gesture(
                    DragGesture()
                        .onChanged { value in
                            onDragChanged(value)
                        }
                        .onEnded { value in
                            onDragEnded(value)
                        }
                )
            ) : AnyView(content)
        
        return contentWithDrag.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPressed(part)
                }
        )
    }
}
