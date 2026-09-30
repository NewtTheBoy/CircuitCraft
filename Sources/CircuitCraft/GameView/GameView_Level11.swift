//
//  GameView_Level11.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level11: View {
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

    @State private var longPressedPart: Part? = nil
    @State private var showActionSheet: Bool = false

    @State private var showWarningAlert: Bool = false
    @State private var warningMessage: String = ""

    @State private var levelCleared: Bool = false
    @State private var showTutorial: Bool = true

    // Level 11 allows only these parts.
    let availableParts = ["input signal", "output signal", "and gate"]

    // Example tutorial pages for Level 11.
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial11_1",
                         title: "AND Gate",
                         description: "An AND gate outputs 1 only if both its inputs are 1. Otherwise, its output is 0."),
            TutorialPage(imageName: "tutorial11_2",
                         title: "Circuit Requirements",
                         description: "Your circuit must contain exactly two Input Signals, exactly one Output Signal, and at least one AND gate."),
            TutorialPage(imageName: "tutorial11_3",
                         title: "Goal",
                         description: "Set one Input Signal to 1 and the other to 0 so that the AND gate computes 0, and ensure that the final Output Signal is 0.")
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
                          outputFixed: false)  // All parts can be moved/added.
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
                    // Place new parts at the board center.
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
                warningMessage = "Output Signal cannot be a connection source"
                return
            } else {
                pendingTargetPart = part
                showSetSourceAlert = true
            }
        } else if connectionSourcePart!.id != part.id {
            if part.imageName == "input signal" {
                warningMessage = "Input Signal cannot be a connection target"
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
        // Process non-AND gate connections first.
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName != "and gate" {
                boardParts[targetIndex].signal = boardParts[sourceIndex].signal
            }
        }
        
        // Now process AND gate parts.
        for index in boardParts.indices {
            if boardParts[index].imageName == "and gate" {
                let inputs = connections.filter { $0.target == boardParts[index].id }
                if inputs.count == 2 {
                    let inputSignals = inputs.compactMap { connection in
                        boardParts.first(where: { $0.id == connection.source })?.signal
                    }
                    if inputSignals.count == 2 {
                        // AND gate logic: output is 1 only if both inputs are 1; otherwise, 0.
                        boardParts[index].signal = (inputSignals[0] == 1 && inputSignals[1] == 1) ? 1 : 0
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
        // For Level 11, require:
        // - Exactly 2 Input Signals.
        // - Exactly 1 Output Signal.
        // - At least 1 AND gate.
        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let andGateParts = boardParts.filter { $0.imageName == "and gate" }

        guard inputParts.count == 2, outputParts.count == 1, !andGateParts.isEmpty else {
            levelCleared = false
            return
        }

        // Ensure all input and output parts are connected.
        guard inputParts.allSatisfy({ part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }) else {
            warningMessage = "Both Input Signals must be connected."
            showWarningAlert = true
            levelCleared = false
            return
        }
        guard let connectedOutput = outputParts.first(where: { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }) else {
            warningMessage = "The Output Signal must be connected."
            showWarningAlert = true
            levelCleared = false
            return
        }

        // Check the goal:
        // In Level 11, the AND gate should compute its output based on the two inputs.
        // For the given design, we expect one input to be 1 and the other 0, so the AND gate will output 0.
        // Then the final output signal must be 0.
        let inputsValid = inputParts.contains(where: { $0.signal == 1 }) &&
                          inputParts.contains(where: { $0.signal == 0 })
        let outputCondition = (connectedOutput.signal == 0)
        if inputsValid && outputCondition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let currentInputs = boardParts.filter { $0.imageName == "input signal" }
                let currentOutputs = boardParts.filter { $0.imageName == "output signal" }
                let currentAndGates = boardParts.filter { $0.imageName == "and gate" }
                if currentInputs.count == 2,
                   currentOutputs.count == 1,
                   !currentAndGates.isEmpty,
                   currentInputs.contains(where: { $0.signal == 1 }) &&
                   currentInputs.contains(where: { $0.signal == 0 }) &&
                   currentOutputs.allSatisfy({ $0.signal == 0 }) {
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
        // Unlock Level 12.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 12 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
