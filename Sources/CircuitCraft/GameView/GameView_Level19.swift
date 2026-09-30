//
//  GameView_Level19.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level19: View {
    @EnvironmentObject var levelStore: LevelStore
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    // 固定的电路部件
    @State private var boardParts: [Part] = [
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 100), signal: 1), // 输入 1 (A)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 200), signal: 1), // 输入 1 (B)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 300), signal: 1), // 输入 1 (C)
        Part(imageName: "and gate", position: CGPoint(x: 300, y: 150), signal: 0),           // AND 门
        Part(imageName: "nor gate", position: CGPoint(x: 300, y: 250), signal: 0),           // NOR 门
        Part(imageName: "nand gate", position: CGPoint(x: 450, y: 200), signal: 0),          // NAND 门
        Part(imageName: "changable output signal", position: CGPoint(x: 600, y: 200), signal: 0) // 输出
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
        // 固定连接
        connections = [
            Connection(source: boardParts[0].id, target: boardParts[3].id), // 输入 A 到 AND
            Connection(source: boardParts[1].id, target: boardParts[3].id), // 输入 B 到 AND
            Connection(source: boardParts[1].id, target: boardParts[4].id), // 输入 B 到 NOR
            Connection(source: boardParts[2].id, target: boardParts[4].id), // 输入 C 到 NOR
            Connection(source: boardParts[3].id, target: boardParts[5].id), // AND 到 NAND
            Connection(source: boardParts[4].id, target: boardParts[5].id), // NOR 到 NAND
            Connection(source: boardParts[5].id, target: boardParts[6].id)  // NAND 到输出
        ]
    }

    private func checkResult() {
        // 正确输出：NAND 输出为 1（1 NAND 0 = 1）
        let correctOutput = 1
        let playerOutput = boardParts[6].signal // 最后一个输出

        if playerOutput == correctOutput {
            levelCleared = true
        } else {
            showRetry = true
        }
    }

    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 20 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        // 重置输出值为初始值 0
        boardParts[6].signal = 0
        levelCleared = false
        showRetry = false
    }
}


// MARK: - Preview
struct GameView_Level19_Previews: PreviewProvider {
    static var previews: some View {
        GameView_Level19()
            .environmentObject(LevelStore())
    }
}
