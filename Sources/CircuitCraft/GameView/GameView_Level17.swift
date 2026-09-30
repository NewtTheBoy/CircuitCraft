//
//  GameView_Level17.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level17: View {
    @EnvironmentObject var levelStore: LevelStore
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    // 固定的电路部件
    @State private var boardParts: [Part] = [
        Part(imageName: "static input signal", position: CGPoint(x: 200, y: 150), signal: 1), // 输入 1
        Part(imageName: "static input signal", position: CGPoint(x: 200, y: 250), signal: 0), // 输入 0
        Part(imageName: "nor gate", position: CGPoint(x: 400, y: 200), signal: 0),           // NOR 门
        Part(imageName: "changable output signal", position: CGPoint(x: 600, y: 200), signal: 0) // 输出初始为 0
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
                updateSignals()
            }
            .overlay(
                Group {
                    if levelCleared {
                        LevelClearOverlayView(
                            onHome: {
                                unlockNextLevel()
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
        // 固定连接：两个输入 -> NOR 门 -> 输出
        connections = [
            Connection(source: boardParts[0].id, target: boardParts[2].id), // 输入 1 到 NOR
            Connection(source: boardParts[1].id, target: boardParts[2].id), // 输入 0 到 NOR
            Connection(source: boardParts[2].id, target: boardParts[3].id)  // NOR 到输出
        ]
    }

    private func updateSignals() {
        // 重置非输入信号
        for index in boardParts.indices {
            if boardParts[index].imageName != "static input signal" {
                boardParts[index].signal = 0
            }
        }

        // 信号传播
        for _ in 0..<boardParts.count {
            for connection in connections {
                guard let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
                      let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }) else {
                    continue
                }

                let sourcePart = boardParts[sourceIndex]
                let targetPart = boardParts[targetIndex]

                switch targetPart.imageName {
                case "nor gate":
                    // NOR 逻辑：所有输入为 0 输出 1，否则输出 0
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.allSatisfy { $0 == 0 } ? 1 : 0
                case "changable output signal":
                    boardParts[targetIndex].signal = sourcePart.signal
                default:
                    break
                }
            }
        }
    }

    private func checkResult() {
        // 正确输出应为 0（输入 1 和 0 通过 NOR 门）
        let correctOutput = 0
        let playerOutput = boardParts[3].signal // 输出信号在第四个位置

        if playerOutput == correctOutput {
            levelCleared = true
        } else {
            showRetry = true
        }
    }

    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 18 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        // 重置输出值为初始值 0，保持输入和连接不变
        boardParts[3].signal = 0
        levelCleared = false
        showRetry = false
        updateSignals()
    }
}


// MARK: - Preview
struct GameView_Level17_Previews: PreviewProvider {
    static var previews: some View {
        GameView_Level17()
            .environmentObject(LevelStore())
    }
}
