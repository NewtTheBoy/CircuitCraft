//
//  BoardView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

// MARK: - EmptyModifier (for fallback)
struct EmptyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

// MARK: - BoardView

struct BoardView: View {
    @Binding var boardParts: [Part]
    @Binding var boardSize: CGSize
    @Binding var connections: [Connection]
    
    // Collect each part's size keyed by its ID.
    @State private var partSizes: [UUID: CGSize] = [:]

    
    // State for trash bin detection.
    @State private var trashBinFrame: CGRect = .zero
    @State private var isOverTrash: Bool = false
    
    let onPartLongPressed: (Part) -> Void
    /// New parameter to control if output signals are fixed (i.e. not draggable/deletable)
    let outputFixed: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background grid.
                CircuitBoardBackground()
                
                // Draw all connections.
                ForEach(connections) { connection in
                    Group {
                        if let source = boardParts.first(where: { $0.id == connection.source }),
                           let target = boardParts.first(where: { $0.id == connection.target }) {
                            
                            let sourceSize = partSizes[source.id] ?? CGSize(width: 50, height: 50)
                            let targetSize = partSizes[target.id] ?? CGSize(width: 50, height: 50)
                            
                            // Calculate the start point: right-center of the source.
                            let startPoint = CGPoint(
                                x: source.position.x + sourceSize.width / CGFloat(2),
                                y: source.position.y
                            )
                            
                            // Check if the target is one of our logic gates that require special attachment.
                            if !(["or gate", "nor gate", "and gate", "nand gate"].contains(target.imageName)) {
                                // For non-gate targets, attach at left-center.
                                let endPoint = CGPoint(
                                    x: target.position.x - targetSize.width / CGFloat(2),
                                    y: target.position.y
                                )
                                WireView(start: startPoint, end: endPoint)
                            } else {
                                // For OR, NOR, AND, and NAND gates, determine the input index.
                                let inputs = connections.filter { $0.target == target.id }
                                if let idx = inputs.firstIndex(where: { $0.id == connection.id }) {
                                    let topEdge = target.position.y - targetSize.height / CGFloat(2)
                                    if idx == 0 {
                                        // First connection: attach at 1/3 from the top.
                                        let endPoint = CGPoint(
                                            x: target.position.x - targetSize.width / CGFloat(2),
                                            y: topEdge + targetSize.height * (CGFloat(1) / CGFloat(3))
                                        )
                                        WireView(start: startPoint, end: endPoint)
                                    } else if idx == 1 {
                                        // Second connection: attach at 2/3 from the top.
                                        let endPoint = CGPoint(
                                            x: target.position.x - targetSize.width / CGFloat(2),
                                            y: topEdge + targetSize.height * (CGFloat(2) / CGFloat(3))
                                        )
                                        WireView(start: startPoint, end: endPoint)
                                    } else {
                                        // If there are already two connections, do not draw an extra line.
                                        EmptyView()
                                    }
                                } else {
                                    EmptyView()
                                }
                            }
                        } else {
                            EmptyView()
                        }
                    }
                }



                
                // Draw all parts.
                ForEach($boardParts) { $part in
                                    Group {
                                        if part.imageName == "input signal" {
                                            InputSignalPartView(part: $part)
                                        } else if part.imageName == "output signal" {
                                            OutputSignalPartView(part: $part)
                                        } else if part.imageName == "not gate" {
                                            NotGatePartView(part: $part)
                                        } else if part.imageName == "or gate" {
                                            OrGatePartView(part: $part)
                                        } else if part.imageName == "nor gate" {
                                            NorGatePartView(part: $part)
                                        } else if part.imageName == "and gate" {
                                            AndGatePartView(part: $part)
                                        } else if part.imageName == "nand gate" {
                                            NandGatePartView(part: $part)
                                        } else if part.imageName == "static input signal" {
                                            StaticInputSignalView(part: $part)
                                        } else if part.imageName == "changable output signal" {
                                            ChangableOutputView(part: $part)
                                        } else {
                                            Image(part.imageName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        }
                                    }
                                    .position(part.position)
                                    .modifier(
                                        PartGestureModifier(
                                            part: part,
                                            allowDrag: part.imageName == "output signal" ? !outputFixed : true,
                                            onDragChanged: { value in
                                                if part.imageName == "output signal" {
                                                    if !outputFixed {
                                                        part.position = value.location
                                                    }
                                                } else {
                                                    part.position = value.location
                                                }
                                                if trashBinFrame.contains(value.location) {
                                                    isOverTrash = true
                                                } else {
                                                    isOverTrash = false
                                                }
                                            },
                                            onDragEnded: { value in
                                                let currentPartID = part.id // 保存当前 part 的 ID
                                                if (part.imageName != "output signal") || (!outputFixed) {
                                                    if trashBinFrame.contains(value.location) {
                                                        // 使用 ID 安全移除，避免绑定问题
                                                        if let index = boardParts.firstIndex(where: { $0.id == currentPartID }) {
                                                            boardParts.remove(at: index)
                                                            connections.removeAll { $0.source == currentPartID || $0.target == currentPartID }
                                                        }
                                                    }
                                                }
                                                isOverTrash = false
                                            },
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
                        .overlay(
                            TrashBinContainerView(trashBinFrame: $trashBinFrame, isActive: isOverTrash),
                            alignment: .bottomLeading
                        )
                    }
                }
