//
//  GameView_Level14.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct GameView_Level14: View {
    @EnvironmentObject var levelStore: LevelStore   // Shared level data
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

    // Level 14 allowed parts: only "input signal", "output signal", and "nand gate"
    let availableParts = ["input signal", "output signal", "nand gate"]

    // Tutorial pages for Level 14 (short version)
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial13_1",
                         title: "NAND Gate Logic",
                         description: "A NAND gate outputs 0 only if both its inputs are 1; otherwise, it outputs 1."),
            TutorialPage(imageName: "tutorial14_2",
                         title: "Circuit Requirements",
                         description: "Your circuit must have exactly 3 Input Signals (sorted as [0, 0, 1]) and 2 Output Signals (sorted as [1, 1]). All parts must be connected and no Input may connect directly to an Output."),
            TutorialPage(imageName: "tutorial14_2",
                         title: "Goal",
                         description: "Arrange your circuit so that the 3 inputs are [0, 0, 1] and the 2 outputs are [1, 1].")
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                // BoardView displays the circuit. All parts can be freely added/moved.
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: false)
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
                    // Place new parts at the center.
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
                // Do not allow output as connection source.
                return
            } else {
                pendingTargetPart = part
                showSetSourceAlert = true
            }
        } else if connectionSourcePart!.id != part.id {
            if part.imageName == "input signal" {
                // Do not allow input as connection target.
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
        // Process NAND gate parts.
        // For each NAND gate with exactly 2 inputs, its output is computed as:
        // If both inputs are 1, output 0; otherwise, output 1.
        for index in boardParts.indices {
            if boardParts[index].imageName == "nand gate" {
                let inputs = connections.filter { $0.target == boardParts[index].id }
                if inputs.count == 2 {
                    let inputSignals = inputs.compactMap { connection in
                        boardParts.first(where: { $0.id == connection.source })?.signal
                    }
                    if inputSignals.count == 2 {
                        boardParts[index].signal = (inputSignals[0] == 1 && inputSignals[1] == 1) ? 0 : 1
                    } else {
                        boardParts[index].signal = 0
                    }
                } else {
                    boardParts[index].signal = 0
                }
            }
        }
        
        // Propagate signal for non-NAND targets.
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName != "nand gate" {
                boardParts[targetIndex].signal = boardParts[sourceIndex].signal
            }
        }
    }

    private func checkLevelClear() {
        // Level 14 Requirements:
        // - Exactly 3 Input Signals (sorted, they must equal [0, 0, 1])
        // - Exactly 2 Output Signals (sorted, they must equal [1, 1])
        // - At least one NAND gate must be present.
        // - All Input and Output parts must be connected.
        // - No direct connection from an Input to an Output is allowed.

        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let nandGateParts = boardParts.filter { $0.imageName == "nand gate" }

        guard inputParts.count == 3, outputParts.count == 2, !nandGateParts.isEmpty else {
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

        // Disallow any direct connection from an Input to an Output.
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

        // Check Input condition: the sorted input signals must equal [0, 0, 1]
        let inputSignals = inputParts.map { $0.signal }
        let sortedInputSignals = inputSignals.sorted()
        let inputCondition = sortedInputSignals == [0, 0, 1]

        // Check Output condition: the sorted output signals must equal [1, 1]
        let outputSignals = outputParts.map { $0.signal }
        let sortedOutputSignals = outputSignals.sorted()
        let outputCondition = sortedOutputSignals == [0, 1]

        if inputCondition && outputCondition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let currentInputs = boardParts.filter { $0.imageName == "input signal" }
                let currentOutputs = boardParts.filter { $0.imageName == "output signal" }
                if currentInputs.map({ $0.signal }).sorted() == [0, 0, 1] &&
                   currentOutputs.map({ $0.signal }).sorted() == [0, 1] {
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
        // Unlock Level 15.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 15 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
