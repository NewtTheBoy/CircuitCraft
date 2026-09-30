//
//  GameView_Level3.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/15/25.
//

import SwiftUI

struct GameView_Level3: View {
    @EnvironmentObject var levelStore: LevelStore  // Shared level store
    @Environment(\.presentationMode) var presentationMode

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
    
    // Available parts for this level.
    // In this level, the player must add components manually.
    let availableParts = ["input signal", "output signal", "not gate"]
    
    // Example tutorial pages for Level 3.
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial3_1", title: "Add Components", description: "From this level, the board is empty—add your components manually to build a circuit."),
            TutorialPage(imageName: "tutorial3_2", title: "Circuit Requirements", description: "Your circuit must contain exactly one Input Signal and exactly two Output Signals."),
            TutorialPage(imageName: "tutorial3_3", title: "Goal", description: "The two Output Signals must show different values (one 0 and one 1) to clear the level. Connect them properly!")
        ]
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                // BoardView displays the circuit. (Here, outputFixed is false since no pre-added parts.)
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
                    // Place newly added parts at the center (or you can decide a different default).
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
        // Overlay: Level Clear
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
        // Overlay: Tutorial
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
        refreshNonInputParts()
        updateSignals()
    }
    
    private func refreshNonInputParts() {
        for index in boardParts.indices {
            if boardParts[index].imageName != "input signal" {
                boardParts[index].signal = 0
            }
        }
    }
    
    private func updateSignals() {
        for connection in connections {
            if let sourceIndex = boardParts.firstIndex(where: { $0.id == connection.source }),
               let targetIndex = boardParts.firstIndex(where: { $0.id == connection.target }) {
                let sourcePart = boardParts[sourceIndex]
                let computedSignal: Int = (sourcePart.imageName == "not gate") ?
                    (sourcePart.signal == 1 ? 0 : 1) :
                    sourcePart.signal
                boardParts[targetIndex].signal = computedSignal
            }
        }
    }
    
    private func checkLevelClear() {
        // Get exactly one input and exactly two outputs.
        let inputParts = boardParts.filter { $0.imageName == "input signal" }
        let outputParts = boardParts.filter { $0.imageName == "output signal" }
        
        // Must have exactly one input and two outputs.
        guard inputParts.count == 1, outputParts.count == 2 else { return }
        
        // Check that each required part is connected.
        // For input:
        guard let connectedInput = inputParts.first(where: { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }) else {
            // Input is not connected.
            warningMessage = "The Input Signal must be connected in the circuit."
            showWarningAlert = true
            return
        }
        
        // For outputs:
        let connectedOutputs = outputParts.filter { part in
            connections.contains { $0.source == part.id || $0.target == part.id }
        }
        guard connectedOutputs.count == 2 else {
            warningMessage = "Both Output Signals must be connected in the circuit."
            showWarningAlert = true
            return
        }
        
        // Check that the outputs have one 0 and one 1.
        let outputSignals = outputParts.map { $0.signal }
        guard outputSignals.contains(0) && outputSignals.contains(1) else { return }
        
        // All conditions met: schedule level clear if not already cleared.
        if !levelCleared {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Double-check the conditions:
                let inputCheck = boardParts.filter { $0.imageName == "input signal" }
                let outputCheck = boardParts.filter { $0.imageName == "output signal" }
                let connectedInputCheck = inputCheck.first(where: { part in
                    connections.contains { $0.source == part.id || $0.target == part.id }
                })
                let connectedOutputsCheck = outputCheck.filter { part in
                    connections.contains { $0.source == part.id || $0.target == part.id }
                }
                let outputSignalsCheck = outputCheck.map { $0.signal }
                
                if inputCheck.count == 1,
                   outputCheck.count == 2,
                   connectedInputCheck != nil,
                   connectedOutputsCheck.count == 2,
                   outputSignalsCheck.contains(0),
                   outputSignalsCheck.contains(1) {
                    levelCleared = true
                }
            }
        }
    }
    
    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 4 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }

    
    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        levelCleared = false
    }
}
