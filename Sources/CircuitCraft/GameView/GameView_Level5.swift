//
//  GameView_Level5.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level5: View {
    @EnvironmentObject var levelStore: LevelStore  // Shared level data
    @Environment(\.presentationMode) var presentationMode  // 用于返回上一级

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

    // 本关可用的组件：
    // "input signal"、"output signal"、"not gate"、"or gate"
    let availableParts = ["input signal", "output signal", "not gate", "or gate"]

    // 示例教学页面
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial5_1", title: "Circuit Requirements", description: "Your circuit must contain exactly two Input Signals, exactly one Output Signal."),
            TutorialPage(imageName: "tutorial5_2", title: "Goal", description: "Ensure that both Input Signals are set to 1 and the final Output is 0. All components must be connected in a valid circuit.")
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                // BoardView 显示电路
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: false) // 关卡中所有部件均可自由添加与移动
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
                    // 默认把新添加的部件放在屏幕中间
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
    
    // MARK: - Connection and Operation Logic
    
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
        // 1. 处理 NOT 门
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName == "not gate" {
                let sourceSignal = boardParts[sourceIndex].signal
                boardParts[targetIndex].signal = (sourceSignal == 1 ? 0 : 1)
            }
        }
        
        // 2. 处理 OR 门
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
        
        // 3. 处理其他连线（直接传递信号）。
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
        // 筛选出各类部件
        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let orGateParts = boardParts.filter { $0.imageName == "or gate" }
        let notGateParts = boardParts.filter { $0.imageName == "not gate" }
        
        // 基本数量要求：2个输入、1个输出、至少1个 OR 门 和 1个 NOT 门
        guard inputParts.count == 2,
              outputParts.count == 1,
              !orGateParts.isEmpty,
              !notGateParts.isEmpty else {
            levelCleared = false
            return
        }
        
        // 检查输入与输出部件是否都参与了连线
        let inputsConnected = inputParts.allSatisfy { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }
        let outputConnected = outputParts.first(where: { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }) != nil
        
        // 检查所有输入的 signal 是否都为 1
        let inputsAreOne = inputParts.allSatisfy { $0.signal == 1 }
        // 检查输出的 signal 是否为 0
        let outputCondition = outputParts.first?.signal == 0
        
        // 如果所有条件都满足，则延迟 1 秒后确认关卡通关
        if inputsConnected && outputConnected && inputsAreOne && outputCondition {
            if !levelCleared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // 再次检查确保条件稳定
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
        // Unlock Level 6.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 6 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }
    
    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
