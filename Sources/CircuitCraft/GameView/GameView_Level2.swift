//
//  GameView_Level2.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/10/25.
//

//
//  GameView_Level2.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/10/25.
//

import SwiftUI

struct GameView_Level2: View {
    @EnvironmentObject var levelStore: LevelStore  // Shared level data
    @Environment(\.presentationMode) var presentationMode


    @State private var boardParts: [Part] = []
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
    
    let availableParts = ["input signal", "output signal", "not gate"]
    
    // Pre-add the output signal; players cannot add a second one.
    init() {
        let outputPart = Part(imageName: "output signal", position: CGPoint(x: 600, y: 150), signal: 0)
        _boardParts = State(initialValue: [outputPart])
    }
    
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial2_1", title: "Not Gate", description: "This is Not Gate. It inverts its input: if the input is 1, the output is 0; if the input is 0, the output is 1."),
            TutorialPage(imageName: "tutorial2_2", title: "Goal", description: "In Level 2, try to use the Not Gate so that the Output Signal becomes 1 to clear the level.")
        ]
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: true)
                    .coordinateSpace(name: "board")
                    .edgesIgnoringSafeArea(.all)
                
                PartsSidebarView(availableParts: availableParts) { partName in
                    if partName == "output signal" {
                        warningMessage = "Level 2 already has an Output Signal"
                        showWarningAlert = true
                    } else {
                        selectedPartName = partName
                        showAddConfirmation = true
                    }
                }
                .frame(width: 80)
                .padding(.trailing, 16)
                .padding(.vertical, 16)
            }
        }
        .alert("Add Part", isPresented: $showAddConfirmation, actions: {
            Button("Cancel", role: .cancel) { selectedPartName = nil }
            Button("Add") {
                if let partName = selectedPartName {
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
        // Check if the output signal is 1.
        if let outputPart = boardParts.first(where: { $0.imageName == "output signal" }),
           outputPart.signal == 1 {

            // Determine if any NOT gate is used in a connection.
            // 1. Get the IDs of all parts that are NOT gates.
            let notGateIDs = boardParts.filter { $0.imageName == "not gate" }.map { $0.id }
            // 2. Check if any connection involves a NOT gate.
            let notGateUsed = connections.contains { connection in
                notGateIDs.contains(connection.source) || notGateIDs.contains(connection.target)
            }

            // If no NOT gate is used, show a warning and do not clear the level.
            if !notGateUsed {
                warningMessage = "You must include a NOT gate in your circuit to clear the level!"
                showWarningAlert = true
                return
            }

            // If a NOT gate is used and level hasn't been marked as cleared,
            // wait for one second before marking the level as cleared.
            if !levelCleared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Double-check the condition.
                    if let updatedOutput = boardParts.first(where: { $0.imageName == "output signal" }),
                       updatedOutput.signal == 1 {
                        levelCleared = true
                    }
                }
            }
        }
    }

    
    // Unlock next level if desired (for Level2, unlocking might be different)
    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 3 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }
    
    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        let outputPart = Part(imageName: "output signal", position: CGPoint(x: 600, y: 150), signal: 0)
        boardParts.append(outputPart)
        levelCleared = false
    }
}
