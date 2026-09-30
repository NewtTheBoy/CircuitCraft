//
//  GameView_Level12.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level12: View {
    @EnvironmentObject var levelStore: LevelStore   // Shared level data
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

    @State private var levelCleared: Bool = false
    @State private var showTutorial: Bool = true

    // Level12 allowed parts: only "input signal", "output signal", "and gate"
    let availableParts = ["input signal", "output signal", "and gate"]

    // Tutorial pages for Level12
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial12_1",
                         title: "Circuit Requirements",
                         description: "Your circuit must have exactly three Input Signals (with two 1’s and one 0) and exactly two Output Signals. Use at least one AND gate. No direct Input-to-Output connection is allowed."),
            TutorialPage(imageName: "tutorial12_2",
                         title: "Goal",
                         description: "Arrange your circuit so that the inputs are [0, 1, 1] (order not important) and the outputs are [0, 1] – meaning one output is 0 and the other is 1.")
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                // BoardView displays the circuit (all parts are movable/added freely).
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
                // Do not allow output to be connection source.
                return
            } else {
                pendingTargetPart = part
                showSetSourceAlert = true
            }
        } else if connectionSourcePart!.id != part.id {
            if part.imageName == "input signal" {
                // Do not allow input to be connection target.
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
        // For Level12, we assume that the NOR gate components (i.e. "and gate" in Level11 context)
        // are not used. Here, we directly propagate signals.
        // For each connection, the target receives the source's signal.
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }) {
                boardParts[targetIndex].signal = boardParts[sourceIndex].signal
            }
        }
    }

    private func checkLevelClear() {
        // Level12 Requirements:
        // - Exactly 3 Input Signals with two 1’s and one 0 (order not important).
        // - Exactly 2 Output Signals, which must equal [0, 1] (one output is 0 and one is 1).
        // - At least 1 AND gate.
        // - All Input and Output parts must be connected.
        // - No direct connection from an Input to an Output is allowed.

        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        let andGateParts = boardParts.filter { $0.imageName == "and gate" }

        // Check part counts
        guard inputParts.count == 3, outputParts.count == 2, !andGateParts.isEmpty else {
            levelCleared = false
            return
        }

        // Check that all inputs and outputs are connected
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

        // Ensure no direct connection from an Input to an Output
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

        // Check input signals: must have exactly two 1’s and one 0
        let inputSignals = inputParts.map { $0.signal }
        let inputOneCount = inputSignals.filter { $0 == 1 }.count
        let inputZeroCount = inputSignals.filter { $0 == 0 }.count
        guard inputOneCount == 2, inputZeroCount == 1 else {
            levelCleared = false
            return
        }

        // Check output signals: must be [0, 1] when sorted
        let outputSignals = outputParts.map { $0.signal }
        let sortedOutputs = outputSignals.sorted()
        guard sortedOutputs == [0, 1] else {
            levelCleared = false
            return
        }

        // If all conditions pass, delay slightly to ensure signal propagation, then confirm
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let currentInputs = boardParts.filter { $0.imageName == "input signal" }
            let currentOutputs = boardParts.filter { $0.imageName == "output signal" }
            let currentAndGates = boardParts.filter { $0.imageName == "and gate" }
            
            let currentInputSignals = currentInputs.map { $0.signal }
            let currentOneCount = currentInputSignals.filter { $0 == 1 }.count
            let currentZeroCount = currentInputSignals.filter { $0 == 0 }.count
            let currentOutputSignals = currentOutputs.map { $0.signal }.sorted()
            
            if currentInputs.count == 3 &&
               currentOutputs.count == 2 &&
               !currentAndGates.isEmpty &&
               currentOneCount == 2 &&
               currentZeroCount == 1 &&
               currentOutputSignals == [0, 1] {
                levelCleared = true
            } else {
                levelCleared = false
            }
        }
    }

    private func unlockNextLevel() {
        // Unlock Level 13.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 13 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
