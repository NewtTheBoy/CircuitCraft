//
//  GameView_Level4.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/18/25.
//

import SwiftUI

struct GameView_Level4: View {
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
    
    // For Level 4, the player can add components manually.
    // Available parts include "input signal", "output signal", "not gate", and "or gate".
    let availableParts = ["input signal", "output signal", "not gate", "or gate"]
    
    // Example tutorial pages for Level 4.
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial4_1", title: "Or Gate", description: "An OR gate is a digital logic component that outputs 1 if at least one of its inputs is 1, and outputs 0 only when both inputs are 0."),
            TutorialPage(imageName: "tutorial4_2", title: "Circuit Requirements", description: "Your circuit must contain exactly two Input Signal, exactly one Output Signals, and at least one OR gate. The OR gate will compute its output only if it has exactly two inputs."),
            TutorialPage(imageName: "tutorial4_3", title: "Goal", description: "The goal is for Output Signals to show 1. Ensure your OR gate is properly connected with two inputs so it computes correctly.")
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
                          outputFixed: false)  // In level 4, all parts can be added/moved.
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
                if let source = connectionSourcePart, let target = pendingTargetPart, source.id != target.id {
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
        // First, update all non-OR gate targets.
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }),
               boardParts[targetIndex].imageName != "or gate" {
                
                let sourcePart = boardParts[sourceIndex]
                var computedSignal = sourcePart.signal
                if sourcePart.imageName == "not gate" {
                    computedSignal = (sourcePart.signal == 1 ? 0 : 1)
                }
                boardParts[targetIndex].signal = computedSignal
            }
        }
        
        // Now, process OR gate parts separately.
        for index in boardParts.indices {
            if boardParts[index].imageName == "or gate" {
                // Gather all connections targeting this OR gate.
                let inputs = connections.filter { $0.target == boardParts[index].id }
                // If exactly two connections exist, compute the OR.
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
                    // If not exactly two inputs, OR gate output remains 0.
                    boardParts[index].signal = 0
                }
            }
        }
    }
    
    private func checkLevelClear() {
        // Get all OR gate parts.
        let orGateParts = boardParts.filter { $0.imageName == "or gate" }
        // Get all output parts.
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        
        // We require that the circuit uses at least one OR gate...
        guard !orGateParts.isEmpty else { return }
        
        // ...and that all output parts have a signal value of 1.
        guard !outputParts.isEmpty, outputParts.allSatisfy({ $0.signal == 1 }) else { return }
        
        // If conditions are met and level isn't already cleared, schedule level clear.
        if !levelCleared {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Double-check the conditions.
                let currentOrGates = boardParts.filter { $0.imageName == "or gate" }
                let currentOutputs = boardParts.filter { $0.imageName == "output signal" }
                
                if !currentOrGates.isEmpty,
                   !currentOutputs.isEmpty,
                   currentOutputs.allSatisfy({ $0.signal == 1 }) {
                    levelCleared = true
                }
            }
        }
    }

    
    private func unlockNextLevel() {
        // Unlock Level 5.
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 5 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }
    
    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
