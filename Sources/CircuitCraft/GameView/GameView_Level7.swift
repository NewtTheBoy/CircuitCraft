//
//  GameView_Level7.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level7: View {
    @EnvironmentObject var levelStore: LevelStore  // Shared level data
    @Environment(\.presentationMode) var presentationMode  // For dismissing the view

    @State private var boardParts: [Part] = []         // Initially empty board
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

    // In Level 7, the player can add components manually.
    // Available parts include: "input signal", "output signal", "not gate", "nor gate".
    let availableParts = ["input signal", "output signal", "not gate", "nor gate"]

    // Example tutorial pages for Level 7.
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial7_1", title: "NOR Gate", description: "A NOR gate outputs 1 only when both its inputs are 0. Otherwise, if any input is 1, its output becomes 0. In this level, the circuit must include a NOR gate."),
            TutorialPage(imageName: "tutorial7_2", title: "Circuit Requirements", description: "Your circuit must contain exactly two Input Signals, exactly one Output Signal, and at least one NOR gate (with exactly two inputs)."),
            TutorialPage(imageName: "tutorial7_3", title: "Goal", description: "The goal is for the Output Signal to show 0. Build your circuit so that the NOR gate computes properly and drives the output to 0.")
        ]
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                // BoardView displays the circuit.
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: false)  // All parts are addable/movable.
                    .coordinateSpace(name: "board")
                    .edgesIgnoringSafeArea(.all)
                
                // Sidebar for adding parts.
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
                    // Place newly added parts at the center.
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
        // Process non-NOR targets first.
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName != "nor gate" {
                
                let sourcePart = boardParts[sourceIndex]
                var computedSignal = sourcePart.signal
                if sourcePart.imageName == "not gate" {
                    computedSignal = (sourcePart.signal == 1 ? 0 : 1)
                }
                boardParts[targetIndex].signal = computedSignal
            }
        }
        
        // Process NOR gate parts.
        for index in boardParts.indices {
            if boardParts[index].imageName == "nor gate" {
                let inputs = connections.filter { $0.target == boardParts[index].id }
                if inputs.count == 2 {
                    let inputSignals = inputs.compactMap { connection in
                        boardParts.first(where: { $0.id == connection.source })?.signal
                    }
                    if inputSignals.count == 2 {
                        // NOR gate logic: output = 1 if both inputs are 0; otherwise 0.
                        boardParts[index].signal = (inputSignals[0] == 0 && inputSignals[1] == 0) ? 1 : 0
                    } else {
                        boardParts[index].signal = 0
                    }
                } else {
                    boardParts[index].signal = 0
                }
            }
        }
    }
    
    private func checkLevelClear() {
        // 筛选各类部件
        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let norGateParts = boardParts.filter { $0.imageName == "nor gate" }
        
        // 数量要求：恰好 2 个输入，1 个输出，至少 1 个 NOR 门
        guard inputParts.count == 2, outputParts.count == 1, !norGateParts.isEmpty else {
            levelCleared = false
            return
        }
        
        // 检查 Input Signal 与 Output Signal 是否均参与连线
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
        
        // 检查输入的值是否均为 1
        let inputsAreOne = inputParts.allSatisfy { $0.signal == 1 }
        // 检查输出的值是否为 0
        let outputCondition = outputParts.first?.signal == 0
        
        // 如果条件满足，则延迟 1 秒后再次确认（确保状态稳定）
        if inputsAreOne && outputCondition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let currentInputs = boardParts.filter { $0.imageName == "input signal" }
                let currentOutput = boardParts.filter { $0.imageName == "output signal" }
                if currentInputs.allSatisfy({ $0.signal == 1 }) &&
                   currentOutput.first?.signal == 0 {
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
        // Unlock Level 8.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 8 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }
    
    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
