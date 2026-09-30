//
//  GameView_Level30.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level30: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    // 固定的电路部件
    @State private var boardParts: [Part] = [
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 100), signal: 0), // 输入 1 (A)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 200), signal: 1), // 输入 0 (B)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 300), signal: 1), // 输入 1 (C)
        Part(imageName: "static input signal", position: CGPoint(x: 500, y: 300), signal: 0), // 输入 0 (D)
        Part(imageName: "or gate", position: CGPoint(x: 300, y: 150), signal: 0),            // OR 门
        Part(imageName: "changable output signal", position: CGPoint(x: 450, y: 100), signal: 0), // 输出 1 (OR)
        Part(imageName: "and gate", position: CGPoint(x: 300, y: 250), signal: 0),           // AND 门
        Part(imageName: "changable output signal", position: CGPoint(x: 450, y: 250), signal: 0), // 输出 2 (AND)
        Part(imageName: "nand gate", position: CGPoint(x: 450, y: 175), signal: 0),          // NAND 门
        Part(imageName: "nor gate", position: CGPoint(x: 600, y: 200), signal: 0),           // NOR 门
        Part(imageName: "changable output signal", position: CGPoint(x: 750, y: 200), signal: 0)  // 输出 3 (NOR)
    ]
    @State private var connections: [Connection] = []
    @State private var boardSize: CGSize = .zero

    @State private var levelCleared: Bool = false
    @State private var showRetry: Bool = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CircuitBoardBackground()
                    .edgesIgnoringSafeArea(.all)

                StaticBoardView(boardParts: $boardParts,
                                boardSize: $boardSize,
                                connections: $connections,
                                onPartLongPressed: { _ in })
                    .coordinateSpace(name: "board")

                VStack {
                    Spacer()
                    Button(action: checkResult) {
                        Text("Check")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                boardSize = proxy.size
                initializeConnections()
            }
            .overlay(
                Group {
                    if levelCleared {
                        FinalClearOverlayView(
                            onHome: {
                                presentationMode.wrappedValue.dismiss()
                            },
                            onRetry: {
                                resetLevel()
                            }
                        )
                    } else if showRetry {
                        RetryOverlayView(
                            onRetry: {
                                resetLevel()
                            }
                        )
                    }
                }
            )
        }
    }

    // MARK: - Logic Functions

    private func initializeConnections() {
        // 固定连接
        connections = [
            // OR 门
            Connection(source: boardParts[0].id, target: boardParts[4].id), // 输入 A 到 OR
            Connection(source: boardParts[1].id, target: boardParts[4].id), // 输入 B 到 OR
            Connection(source: boardParts[4].id, target: boardParts[5].id), // OR 到输出 1
            // AND 门
            Connection(source: boardParts[1].id, target: boardParts[6].id), // 输入 A 到 AND
            Connection(source: boardParts[2].id, target: boardParts[6].id), // 输入 C 到 AND
            Connection(source: boardParts[6].id, target: boardParts[7].id), // AND 到输出 2
            // NAND 和 NOR 门
            Connection(source: boardParts[4].id, target: boardParts[8].id), // OR 到 NAND
            Connection(source: boardParts[6].id, target: boardParts[8].id), // AND 到 NAND
            Connection(source: boardParts[8].id, target: boardParts[9].id), // NAND 到 NOR
            Connection(source: boardParts[3].id, target: boardParts[9].id), // 输入 D 到 NOR
            Connection(source: boardParts[9].id, target: boardParts[10].id) // NOR 到输出 3
        ]
    }

    private func checkResult() {
        // 正确输出：[OR: 1, AND: 1, NOR: 1]
        let correctOutputs = [1, 1, 1]
        let playerOutputs = [
            boardParts[5].signal,  // 输出 1 (OR)
            boardParts[7].signal,  // 输出 2 (AND)
            boardParts[10].signal  // 输出 3 (NOR)
        ]

        if playerOutputs == correctOutputs {
            levelCleared = true
        } else {
            showRetry = true
        }
    }

    private func resetLevel() {
        // 重置所有输出值为初始值 0
        boardParts[5].signal = 0
        boardParts[7].signal = 0
        boardParts[10].signal = 0
        levelCleared = false
        showRetry = false
    }
}

// MARK: - Final Clear 覆盖视图（最后一关专用）
struct FinalClearOverlayView: View {
    let onHome: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Congratulations!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                Text("You've completed all levels!")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Button(action: onHome) {
                    Text("Back to Home")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding()
            .background(Color.gray.opacity(0.8))
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview
struct GameView_Level30_Previews: PreviewProvider {
    static var previews: some View {
        GameView_Level30()
    }
}
