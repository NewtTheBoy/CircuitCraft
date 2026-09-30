//
//  GameView_Level8.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level8: View {
    @EnvironmentObject var levelStore: LevelStore  // 共享关卡数据
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

    // 本关可用组件：
    // "input signal", "output signal", "not gate", "or gate"
    let availableParts = ["input signal", "output signal", "not gate", "or gate"]

    // 示例教学页面
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial8_1",
                         title: "Build NOR with OR+NOT",
                         description: "Connect two Input Signals to an OR gate, then feed its output into a NOT gate. NOR logic: both inputs 0 → output 1; any input 1 → output 0."),
            TutorialPage(imageName: "tutorial8_2",
                         title: "Requirements",
                         description: "You need exactly 2 Input Signals and 1 Output Signal, plus an OR and a NOT gate connected in series."),
            TutorialPage(imageName: "tutorial8_3",
                         title: "Goal",
                         description: "Set the Inputs so that if both are 1 the Output is 0.")
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
                
                // 侧边栏用于添加部件
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
                    // 默认将新添加的部件放在屏幕中央
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
        // 1. 处理 NOT 门：对于每个目标为 NOT 门的连线，其输出为源信号的反转
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName == "not gate" {
                let sourceSignal = boardParts[sourceIndex].signal
                boardParts[targetIndex].signal = (sourceSignal == 1 ? 0 : 1)
            }
        }
        
        // 2. 处理 OR 门：当 OR 门恰有两个输入时，其输出为 (input0 OR input1)；否则输出 0
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
        
        // 3. 对于其他连线，直接传递信号。
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName != "or gate",
               boardParts[targetIndex].imageName != "not gate" {
                boardParts[targetIndex].signal = boardParts[sourceIndex].signal
            }
        }
    }

    private func checkLevelClear() {
        // 本关要求构成如下连线链条：
        // [Input Signal 1] 和 [Input Signal 2] 分别作为两个输入（共2个 Input）
        // 这两个 Input 必须分别连接到同一个 OR 门的两个输入端，
        // OR 门的输出必须连接到 NOT 门，
        // NOT 门的输出连接到唯一的 Output Signal。
        // NOR 逻辑要求：当两个 Input 都为 0 时，期望 NOT 门输出为 1；否则输出 0。
        // 关卡目标：最终输出必须为 0。
        
        // 筛选部件
        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let orGateParts = boardParts.filter { $0.imageName == "or gate" }
        let notGateParts = boardParts.filter { $0.imageName == "not gate" }
        
        // 检查数量要求：2个 Input, 1个 Output, 至少1个 OR, 至少1个 NOT
        guard inputParts.count == 2, outputParts.count == 1,
              !orGateParts.isEmpty, !notGateParts.isEmpty else {
            levelCleared = false
            return
        }
        
        // 检查所有 Input 和 Output 是否均已连线
        let inputsConnected = inputParts.allSatisfy { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }
        let outputConnected = outputParts.first(where: { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }) != nil
        guard inputsConnected, outputConnected else {
            levelCleared = false
            return
        }
        
        // 检查 NOR 连线结构是否正确：
        // 必须存在一个 OR 门，其输入正好来自这两个 Input，
        // 并且存在一个 NOT 门，其输入正好来自该 OR 门，
        // 且 NOT 门的输出连接到 Output。
        guard let validOrGate = orGateParts.first(where: { orGate in
            let orInputs = connections.filter { $0.target == orGate.id }
            // OR 门应有正好 2 个输入，且输入来源必须为这两个 Input Signal
            guard orInputs.count == 2 else { return false }
            let inputIDs = Set(inputParts.map { $0.id })
            let orSourceIDs = Set(orInputs.map { $0.source })
            return orSourceIDs == inputIDs
        }) else {
            levelCleared = false
            return
        }
        
        guard let validNotGate = notGateParts.first(where: { notGate in
            let notInputs = connections.filter { $0.target == notGate.id }
            // NOT 门必须只有一个输入，并且该输入必须来自上面找到的 OR 门
            guard notInputs.count == 1 else { return false }
            return notInputs.first?.source == validOrGate.id
        }) else {
            levelCleared = false
            return
        }
        
        // 检查 NOT 门的输出是否连接到 Output Signal
        guard connections.contains(where: { connection in
            connection.source == validNotGate.id &&
            outputParts.contains(where: { $0.id == connection.target })
        }) else {
            levelCleared = false
            return
        }
        
        // 计算 NOR 逻辑：如果两个 Input 均为 0，则期望输出为 1；否则期望输出为 0
        let inputSignals = inputParts.map { $0.signal }
        let expectedOutput = (inputSignals[0] == 0 && inputSignals[1] == 0) ? 1 : 0
        
        // 检查实际输出与目标是否一致：目标要求 Output 必须为 0
        if let outputSignal = outputParts.first?.signal, outputSignal == expectedOutput, expectedOutput == 0 {
            // 延迟 1 秒后再次确认
            if !levelCleared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let currentInputs = boardParts.filter { $0.imageName == "input signal" }
                    let currentOutput = boardParts.filter { $0.imageName == "output signal" }
                    if currentInputs.allSatisfy({ $0.signal == 1 }) &&
                        currentOutput.first?.signal == 0 {
                        levelCleared = true
                    }
                }
            }
        } else {
            levelCleared = false
        }
    }

    private func unlockNextLevel() {
        // 解锁 Level 9
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 9 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
