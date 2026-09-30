//
//  GameView_Level22.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level22: View {
    @EnvironmentObject var levelStore: LevelStore
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    // 固定的电路部件
    @State private var boardParts: [Part] = [
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 50), signal: 1), // 输入 1 (A)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 125), signal: 0), // 输入 0 (B)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 200), signal: 1), // 输入 1 (C)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 275), signal: 0), // 输入 0 (D)
        Part(imageName: "static input signal", position: CGPoint(x: 150, y: 350), signal: 1), // 输入 1 (E)
        Part(imageName: "and gate", position: CGPoint(x: 300, y: 85), signal: 0),           // AND 门
        Part(imageName: "changable output signal", position: CGPoint(x: 450, y: 85), signal: 0), // 输出 1 (AND)
        Part(imageName: "or gate", position: CGPoint(x: 300, y: 160), signal: 0),            // OR 门
        Part(imageName: "changable output signal", position: CGPoint(x: 450, y: 140), signal: 0), // 输出 2 (OR)
        Part(imageName: "nor gate", position: CGPoint(x: 300, y: 235), signal: 0),           // NOR 门
        Part(imageName: "nand gate", position: CGPoint(x: 450, y: 250), signal: 0),          // NAND 门
        Part(imageName: "changable output signal", position: CGPoint(x: 600, y: 300), signal: 0), // 输出 3 (NAND)
        Part(imageName: "and gate", position: CGPoint(x: 600, y: 250), signal: 0),           // AND 门（第二层）
        Part(imageName: "changable output signal", position: CGPoint(x: 750, y: 200), signal: 0)  // 输出 4 (AND)
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
            // AND 门
            Connection(source: boardParts[0].id, target: boardParts[5].id), // 输入 A 到 AND
            Connection(source: boardParts[1].id, target: boardParts[5].id), // 输入 B 到 AND
            Connection(source: boardParts[5].id, target: boardParts[6].id), // AND 到输出 1
            // OR 门
            Connection(source: boardParts[1].id, target: boardParts[7].id), // 输入 B 到 OR
            Connection(source: boardParts[2].id, target: boardParts[7].id), // 输入 C 到 OR
            Connection(source: boardParts[7].id, target: boardParts[8].id), // OR 到输出 2
            // NOR 和 NAND 门
            Connection(source: boardParts[2].id, target: boardParts[9].id), // 输入 C 到 NOR
            Connection(source: boardParts[3].id, target: boardParts[9].id), // 输入 D 到 NOR
            Connection(source: boardParts[9].id, target: boardParts[10].id), // NOR 到 NAND
            Connection(source: boardParts[4].id, target: boardParts[10].id), // 输入 E 到 NAND
            Connection(source: boardParts[10].id, target: boardParts[11].id), // NAND 到输出 3
            // AND 门（第二层）
            Connection(source: boardParts[7].id, target: boardParts[12].id), // OR 到 AND
            Connection(source: boardParts[10].id, target: boardParts[12].id), // NAND 到 AND
            Connection(source: boardParts[12].id, target: boardParts[13].id) // AND 到输出 4
        ]
    }

    private func checkResult() {
        // 正确输出：[AND: 0, OR: 1, NAND: 1, AND: 1]
        let correctOutputs = [0, 1, 1, 1]
        let playerOutputs = [
            boardParts[6].signal,  // 输出 1 (AND)
            boardParts[8].signal,  // 输出 2 (OR)
            boardParts[11].signal, // 输出 3 (NAND)
            boardParts[13].signal  // 输出 4 (AND)
        ]

        if playerOutputs == correctOutputs {
            levelCleared = true
        } else {
            showRetry = true
        }
    }

    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 23 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        // 重置所有输出值为初始值 0
        boardParts[6].signal = 0
        boardParts[8].signal = 0
        boardParts[11].signal = 0
        boardParts[13].signal = 0
        levelCleared = false
        showRetry = false
    }
}

// MARK: - Preview
struct GameView_Level22_Previews: PreviewProvider {
    static var previews: some View {
        GameView_Level22()
            .environmentObject(LevelStore())
    }
}
