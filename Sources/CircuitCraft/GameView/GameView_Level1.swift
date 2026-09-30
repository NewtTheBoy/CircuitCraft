//
//  GameView_Level1.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/4/25.
//
//  第一关

import SwiftUI

struct GameView_Level1: View {
    @EnvironmentObject var levelStore: LevelStore  // Shared level store
    @Environment(\.presentationMode) var presentationMode  // To dismiss the view
    
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
    
    let availableParts = ["input signal", "output signal"]
    
    // Pre-add the output signal; it cannot be added again.
    init() {
        let outputPart = Part(imageName: "output signal", position: CGPoint(x: 600, y: 150), signal: 0)
        _boardParts = State(initialValue: [outputPart])
    }
    
    var tutorialPages: [TutorialPage] {
        [
            TutorialPage(imageName: "tutorial1_1", title: "Input Signal", description: "The Input Signal is a component that you can add to your circuit board. Tap the Input Signal to select a value (0 or 1) and adjust its state."),
            TutorialPage(imageName: "tutorial1_2", title: "Output Signal", description: "The Output Signal is the terminal component on your circuit board that displays the final output. The output depends on the source (signal sender) of its connection."),
            TutorialPage(imageName: "tutorial1_3", title: "Connection", description: "To connect components, long-press the source (signal sender) and then long-press the target (signal receiver)."),
            TutorialPage(imageName: "tutorial1_4", title: "Goal", description: "In this level, your goal is to achieve an Output Signal value of 1 in order to clear the level. Try with connection and different input value!")
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
                        warningMessage = "Level 1 already has an Output Signal"
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
            .onAppear {
                boardSize = proxy.size
                // Update the output signal position relative to the screen.
                if let index = boardParts.firstIndex(where: { $0.imageName == "output signal" }) {
                    boardParts[index].position = CGPoint(x: boardSize.width * (2.0/3.0),
                                                           y: boardSize.height * 0.5)
                }
                checkLevelClear()
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
                            // Unlock level 2 and dismiss this view to go back to level selection.
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
                let sourceSignal = boardParts[sourceIndex].signal
                let computedSignal = computeOutput(sourceSignal)
                boardParts[targetIndex].signal = computedSignal
            }
        }
    }
    
    private func computeOutput(_ sourceSignal: Int) -> Int {
        return sourceSignal
    }
    
    private func checkLevelClear() {
        if let outputPart = boardParts.first(where: { $0.imageName == "output signal" }),
           outputPart.signal == 1 {
            if !levelCleared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let updatedOutput = boardParts.first(where: { $0.imageName == "output signal" }),
                       updatedOutput.signal == 1 {
                        levelCleared = true
                    }
                }
            }
        }
    }
    
    private func unlockNextLevel() {
        if let index = levelStore.levels.firstIndex(where: { $0.config.levelNumber == 2 }) {
            levelStore.levels[index].isUnlocked = true
        }
    }
    
    private func resetLevel() {
        boardParts.removeAll()
        connections.removeAll()
        let outputPart = Part(imageName: "output signal", position: CGPoint(x: boardSize.width * (2.0/3.0), y: boardSize.height * 0.5), signal: 0)
        boardParts.append(outputPart)
        levelCleared = false
    }
}
