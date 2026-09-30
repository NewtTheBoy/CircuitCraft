//
//  GameView_Level16.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level16: View {
    @EnvironmentObject var levelStore: LevelStore
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var boardParts: [Part] = [
        Part(imageName: "static input signal", position: CGPoint(x: 200, y: 200), signal: 1),
        Part(imageName: "not gate", position: CGPoint(x: 400, y: 200), signal: 0),
        Part(imageName: "changable output signal", position: CGPoint(x: 600, y: 200), signal: 0)
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
                                onPartLongPressed: { _ in }) // 无长按功能
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
        connections = [
            Connection(source: boardParts[0].id, target: boardParts[1].id),
            Connection(source: boardParts[1].id, target: boardParts[2].id)
        ]
    }

    private func updateSignals() {
        for index in boardParts.indices {
            if boardParts[index].imageName != "static input signal" {
                boardParts[index].signal = 0
            }
        }

        for _ in 0..<boardParts.count {
            for connection in connections {
                guard let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
                      let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }) else {
                    continue
                }

                let sourcePart = boardParts[sourceIndex]
                let targetPart = boardParts[targetIndex]

                switch targetPart.imageName {
                case "not gate":
                    boardParts[targetIndex].signal = sourcePart.signal == 1 ? 0 : 1
                case "changable output signal":
                    boardParts[targetIndex].signal = sourcePart.signal
                default:
                    break
                }
            }
        }
    }

    private func checkResult() {
        let correctOutput = 0
        let playerOutput = boardParts[2].signal

        if playerOutput == correctOutput {
            levelCleared = true
        } else {
            showRetry = true
        }
    }

    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 17 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts[2].signal = 0
        levelCleared = false
        showRetry = false
        updateSignals()
    }
}

// MARK: - Retry 覆盖视图
struct RetryOverlayView: View {
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Wrong Answer!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
            .background(Color.gray.opacity(0.8))
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview
struct GameView_Level16_Previews: PreviewProvider {
    static var previews: some View {
        GameView_Level16()
            .environmentObject(LevelStore())
    }
}
