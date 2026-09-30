//
//  GameView_Level15.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level15: View {
    @EnvironmentObject var levelStore: LevelStore  // Shared level data
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>  // For dismissing the view

    @State private var boardParts: [Part] = []         // Initially empty board
    @State private var selectedPartName: String? = nil
    @State private var showAddConfirmation: Bool = false
    @State private var boardSize: CGSize = .zero

    @State private var connections: [Connection] = []

    @State private var connectionSourcePart: Part? = nil
    @State private var showSetSourceAlert: Bool = false
    @State private var showConnectConfirmAlert: Bool = false
    @State private var pendingTargetPart: Part? = nil

    @State private var longPressedPart: Part? = nil
    @State private var showActionSheet: Bool = false

    @State private var levelCleared: Bool = false
    @State private var showTutorial: Bool = true

    // Level 15 allowed parts: all available components
    let availableParts = ["input signal", "output signal", "or gate", "nor gate", "not gate", "and gate", "nand gate"]

    // Tutorial pages for Level 15 (short version)
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial15_1",
                         title: "Level Requirements",
                         description: "Your circuit must have exactly 4 Input Signals (all set to 1) and 3 Output Signals (sorted, they must equal [0, 0, 1])."),
            TutorialPage(imageName: "tutorial15_2",
                         title: "Allowed Components",
                         description: "You may use any gate (OR, NOR, NOT, AND, NAND) but inputs must not connect directly to outputs."),
            TutorialPage(imageName: "tutorial15_1",
                         title: "Goal",
                         description: "Ensure all inputs are 1 and design your circuit so that the outputs, when sorted, equal [0, 0, 1].")
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: false)  // All parts are movable/added freely
                    .coordinateSpace(name: "board")
                    .edgesIgnoringSafeArea(.all)

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
                    let center = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
                    // 输入信号默认设为 1，其他部件初始为 0
                    let initialSignal = partName == "input signal" ? 1 : 0
                    let newPart = Part(imageName: partName, position: center, signal: initialSignal)
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
                if let source = connectionSourcePart, let target = pendingTargetPart, source.id != target.id {
                    let newConnection = Connection(source: source.id, target: target.id)
                    connections.append(newConnection)
                    updateSignals()
                }
                connectionSourcePart = nil
                pendingTargetPart = nil
            }
        }, message: { Text("Do you want to connect the source to this part?") })
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
                return  // 不允许输出作为连接源
            } else {
                pendingTargetPart = part
                showSetSourceAlert = true
            }
        } else if connectionSourcePart!.id != part.id {
            if part.imageName == "input signal" {
                return  // 不允许输入作为连接目标
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
        // 重置所有非输入信号的部件信号，避免旧值干扰
        for index in boardParts.indices {
            if boardParts[index].imageName != "input signal" {
                boardParts[index].signal = 0
            }
        }

        // 多次迭代以确保信号传播完成
        for _ in 0..<boardParts.count {
            for connection in connections {
                guard let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
                      let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }) else {
                    continue
                }

                let sourcePart = boardParts[sourceIndex]
                let targetPart = boardParts[targetIndex]

                // 根据目标部件类型计算信号
                switch targetPart.imageName {
                case "not gate":
                    // NOT: 输入的非
                    boardParts[targetIndex].signal = sourcePart.signal == 1 ? 0 : 1

                case "or gate":
                    // OR: 所有输入中有一个 1 则输出 1
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.contains(1) ? 1 : 0

                case "nor gate":
                    // NOR: 所有输入均为 0 则输出 1，否则输出 0
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.allSatisfy { $0 == 0 } ? 1 : 0

                case "and gate":
                    // AND: 所有输入均为 1 则输出 1，否则输出 0
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.allSatisfy { $0 == 1 } ? 1 : 0

                case "nand gate":
                    // NAND: 所有输入均为 1 则输出 0，否则输出 1
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.allSatisfy { $0 == 1 } ? 0 : 1

                case "output signal":
                    // 输出信号直接接收源信号
                    boardParts[targetIndex].signal = sourcePart.signal

                default:
                    break
                }
            }
        }
    }

    private func checkLevelClear() {
        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        
        // 检查部件数量
        guard inputParts.count == 4, outputParts.count == 3 else {
            levelCleared = false
            return
        }
        
        // 检查所有输入和输出是否已连接
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
        
        // 禁止输入直接连到输出
        let directIO = connections.contains { connection in
            if let source = boardParts.first(where: { $0.id == connection.source }),
               let target = boardParts.first(where: { $0.id == connection.target }) {
                return source.imageName == "input signal" && target.imageName == "output signal"
            }
            return false
        }
        if directIO {
            levelCleared = false
            return
        }
        
        // 检查输入条件：所有输入信号必须为 1
        let inputsAreOne = inputParts.allSatisfy { $0.signal == 1 }
        
        // 检查输出条件：输出信号排序后必须为 [0, 0, 1]
        let outputSignals = outputParts.map { $0.signal }
        let sortedOutputs = outputSignals.sorted()
        let outputCondition = sortedOutputs == [0, 0, 1]
        
        if inputsAreOne && outputCondition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let currentInputs = boardParts.filter { $0.imageName == "input signal" }
                let currentOutputs = boardParts.filter { $0.imageName == "output signal" }
                if currentInputs.allSatisfy({ $0.signal == 1 }) &&
                   currentOutputs.count == 3 &&
                   currentOutputs.map({ $0.signal }).sorted() == [0, 0, 1] {
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
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 16 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}

// MARK: - Preview
struct GameView_Level15_Previews: PreviewProvider {
    static var previews: some View {
        GameView_Level15()
            .environmentObject(LevelStore()) // 提供预览用的环境对象
    }
}
