//
//  GameView_Level9.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level9: View {
    @EnvironmentObject var levelStore: LevelStore   // 共享关卡数据
    @Environment(\.presentationMode) var presentationMode  // 用于返回关卡选择页

    @State private var boardParts: [Part] = []         // 初始为空的电路板
    @State private var selectedPartName: String? = nil
    @State private var showAddConfirmation: Bool = false
    @State private var boardSize: CGSize = .zero

    @State private var connections: [Connection] = []

    @State private var connectionSourcePart: Part? = nil
    @State private var showSetSourceAlert: Bool = false
    @State private var showConnectConfirmAlert: Bool = false
    @State private var pendingTargetPart: Part? = nil

    @State private var showWarningAlert: Bool = false
    @State private var warningMessage: String = ""

    @State private var longPressedPart: Part? = nil
    @State private var showActionSheet: Bool = false

    @State private var levelCleared: Bool = false
    @State private var showTutorial: Bool = true

    // Level9 可用组件：允许使用 "input signal"、"output signal"、"nor gate"、"or gate"
    let availableParts = ["input signal", "output signal", "nor gate", "or gate"]

    // 示例教学页面
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial9_1",
                         title: "Circuit Requirements",
                         description: "Your circuit must contain exactly three Input Signals and exactly two Output Signals. All Input and Output components must be connected in one circuit."),
            TutorialPage(imageName: "tutorial9_2",
                         title: "Goal",
                         description: "Set all three Input Signals to 1. Then design your circuit so that one Output Signal shows 0 and the other shows 1. Verify that all components are connected to form a valid circuit.")
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                // BoardView 显示电路（所有部件均可自由添加、移动）
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: false)
                    .coordinateSpace(name: "board")
                    .edgesIgnoringSafeArea(.all)

                // 侧边栏用于添加组件
                PartsSidebarView(availableParts: availableParts) { partName in
                    selectedPartName = partName
                    showAddConfirmation = true
                }
                .frame(width: 80)
                .padding(.trailing, 16)
                .padding(.vertical, 16)
            }
            .onAppear {
                boardSize = proxy.size
                checkLevelClear()
            }
        }
        .alert("Add Part", isPresented: $showAddConfirmation, actions: {
            Button("Cancel", role: .cancel) { selectedPartName = nil }
            Button("Add") {
                if let partName = selectedPartName {
                    // 默认将新添加的组件放在屏幕中央
                    let center = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
                    let newPart = Part(imageName: partName, position: center, signal: 0)
                    boardParts.append(newPart)
                }
                selectedPartName = nil
            }
        }, message: { Text("Do you want to add this part?") })
        .alert("Set Connection Source", isPresented: $showSetSourceAlert, actions: {
            Button("Cancel", role: .cancel) { connectionSourcePart = nil }
            Button("Set as Source") {
                if let part = pendingTargetPart {
                    connectionSourcePart = part
                }
            }
        }, message: { Text("Do you want to set this part as the connection source?") })
        .alert("Connect Parts", isPresented: $showConnectConfirmAlert, actions: {
            Button("Cancel", role: .cancel) { pendingTargetPart = nil }
            Button("Connect") {
                if let source = connectionSourcePart,
                   let target = pendingTargetPart,
                   source.id != target.id {
                    let newConnection = Connection(source: source.id, target: target.id)
                    connections.append(newConnection)
                    updateSignals()
                }
                connectionSourcePart = nil
                pendingTargetPart = nil
            }
        }, message: { Text("Do you want to connect the source to this part?") })
        .alert("Warning", isPresented: $showWarningAlert) {
            Button("OK", role: .cancel) { warningMessage = "" }
        } message: { Text(warningMessage) }
        .confirmationDialog("Choose Action", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Connect") {
                if let part = longPressedPart {
                    handleConnect(for: part)
                }
            }
            Button("Disconnect") {
                if let part = longPressedPart {
                    handleDisconnect(for: part)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .onChange(of: boardParts.map { $0.signal }) { _ in
            updateSignals()
            checkLevelClear()
        }
        .onAppear {
            checkLevelClear()
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
                }
            }
        )
        .overlay(
            Group {
                if showTutorial {
                    TutorialOverlayView(isPresented: $showTutorial, pages: tutorialPages)
                }
            }
        )
    }

    // MARK: - 连接与操作逻辑

    private func handlePartLongPressed(_ part: Part) {
        longPressedPart = part
        showActionSheet = true
    }

    private func handleConnect(for part: Part) {
        if connectionSourcePart == nil {
            if part.imageName == "output signal" {
                warningMessage = "Output Signal cannot be a connection source"
                showWarningAlert = true
                return
            } else {
                pendingTargetPart = part
                showSetSourceAlert = true
            }
        } else if connectionSourcePart!.id != part.id {
            if part.imageName == "input signal" {
                warningMessage = "Input Signal cannot be a connection target"
                showWarningAlert = true
                return
            } else {
                pendingTargetPart = part
                showConnectConfirmAlert = true
            }
        }
    }

    private func handleDisconnect(for part: Part) {
        connections.removeAll { $0.source == part.id || $0.target == part.id }
        updateSignals()
    }

    private func updateSignals() {
        // 本关中，NOR 门由专用 "nor gate" 实现，其内部逻辑由组件自行处理，
        // 这里我们只对 OR 门（用于信号传递）以及其他非 NOR 部件做直接信号传递。
        // 1. 处理 OR 门：当 OR 门恰有两个输入时，其输出为 (input0 OR input1)；否则输出 0。
        for index in boardParts.indices {
            if boardParts[index].imageName == "or gate" {
                let inputs = connections.filter { $0.target == boardParts[index].id }
                if inputs.count == 2 {
                    let inputSignals = inputs.compactMap { connection in
                        boardParts.first(where: { $0.id == connection.source })?.signal
                    }
                    if inputSignals.count == 2 {
                        boardParts[index].signal = (inputSignals[0] == 1 || inputSignals[1] == 1) ? 1 : 0
                    } else {
                        boardParts[index].signal = 0
                    }
                } else {
                    boardParts[index].signal = 0
                }
            }
        }
        
        // 2. 对于其他连线（不属于 OR 门或 NOR 门），直接传递信号。
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName != "or gate",
               boardParts[targetIndex].imageName != "nor gate" {
                boardParts[targetIndex].signal = boardParts[sourceIndex].signal
            }
        }
    }

    private func checkLevelClear() {
        // Level9 要求：
        // - 恰好有三个 Input Signal，且所有输入的 signal 都为 1
        // - 恰好有两个 Output Signal，其中一个 signal 为 0，另一个为 1
        // - 至少有一个 NOR gate（专用 NOR 门）
        // - 所有 Input 与 Output 部件必须都参与连线

        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let norGateParts = boardParts.filter { $0.imageName == "nor gate" }

        guard inputParts.count == 3, outputParts.count == 2, !norGateParts.isEmpty else {
            levelCleared = false
            return
        }

        let inputsConnected = inputParts.allSatisfy { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }
        let outputsConnected = outputParts.allSatisfy { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }
        guard inputsConnected, outputsConnected else {
            levelCleared = false
            return
        }

        // 检查输入条件：所有输入 signal 均为 1
        let inputsAreOne = inputParts.allSatisfy { $0.signal == 1 }
        // 检查输出条件：两个 Output Signal 中必须有一个为 0，一个为 1
        let outputSignals = outputParts.map { $0.signal }
        let outputCondition = outputSignals.contains(0) && outputSignals.contains(1)

        if inputsAreOne && outputCondition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let currentInputs = boardParts.filter { $0.imageName == "input signal" }
                let currentOutputs = boardParts.filter { $0.imageName == "output signal" }
                if currentInputs.allSatisfy({ $0.signal == 1 }) &&
                   currentOutputs.count == 2 &&
                   currentOutputs.map({ $0.signal }).contains(0) &&
                   currentOutputs.map({ $0.signal }).contains(1) {
                    levelCleared = true
                } else {
                    levelCleared = false
                }
            }
        } else {
            levelCleared = false
        }
    }

    private func unlockNextLevel() {
        // 解锁 Level 10.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 10 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
