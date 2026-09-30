//
//  StaticBoardView.swift
//
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct StaticBoardView: View {
    @Binding var boardParts: [Part]
    @Binding var boardSize: CGSize
    @Binding var connections: [Connection]
    
    @State private var partSizes: [UUID: CGSize] = [:]
    
    let onPartLongPressed: (Part) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CircuitBoardBackground()
                
                ForEach(connections) { connection in
                    Group {
                        if let source = boardParts.first(where: { $0.id == connection.source }),
                           let target = boardParts.first(where: { $0.id == connection.target }) {
                            
                            let sourceSize = partSizes[source.id] ?? CGSize(width: 50, height: 50)
                            let targetSize = partSizes[target.id] ?? CGSize(width: 50, height: 50)
                            
                            let startPoint = CGPoint(
                                x: source.position.x + sourceSize.width / CGFloat(2),
                                y: source.position.y
                            )
                            
                            if !(["or gate", "nor gate", "and gate", "nand gate"].contains(target.imageName)) {
                                let endPoint = CGPoint(
                                    x: target.position.x - targetSize.width / CGFloat(2),
                                    y: target.position.y
                                )
                                WireView(start: startPoint, end: endPoint)
                            } else {
                                let inputs = connections.filter { $0.target == target.id }
                                if let idx = inputs.firstIndex(where: { $0.id == connection.id }) {
                                    let topEdge = target.position.y - targetSize.height / CGFloat(2)
                                    let endPoint = CGPoint(
                                        x: target.position.x - targetSize.width / CGFloat(2),
                                        y: topEdge + targetSize.height * (CGFloat(idx + 1) / CGFloat(3))
                                    )
                                    WireView(start: startPoint, end: endPoint)
                                } else {
                                    EmptyView()
                                }
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }
                
                ForEach($boardParts) { $part in
                    Group {
                        switch part.imageName {
                        case "static input signal":
                            StaticInputSignalView(part: $part)
                        case "changable output signal":
                            ChangableOutputView(part: $part)
                        case "not gate":
                            NotGatePartView(part: $part)
                        case "or gate":
                            OrGatePartView(part: $part)
                        case "nor gate":
                            NorGatePartView(part: $part)
                        case "and gate":
                            AndGatePartView(part: $part)
                        case "nand gate":
                            NandGatePartView(part: $part)
                        default:
                            Image(part.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    .position(part.position)
                    .modifier(
                        PartGestureModifier(
                            part: part,
                            allowDrag: false,
                            onDragChanged: { _ in },
                            onDragEnded: { _ in },
                            onLongPressed: onPartLongPressed
                        )
                    )
                }
            }
            .onAppear {
                boardSize = geo.size
            }
            .onChange(of: geo.size) { newSize in
                boardSize = newSize
            }
            .onPreferenceChange(PartSizePreferenceKey.self) { sizes in
                partSizes = sizes
            }
        }
        .ignoresSafeArea()
    }
}
