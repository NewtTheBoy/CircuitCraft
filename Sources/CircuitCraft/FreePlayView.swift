//
//  FreePlayView.swift
//
//
//  Created by NewtTheBoy on 2/22/25.
//

import SwiftUI

struct FreePlayView: View {
    @State private var boardParts: [Part] = []
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

    // 可用部件列表
    let availableParts = ["input signal", "output signal", "or gate", "nor gate", "not gate", "and gate", "nand gate"]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                BoardView(boardParts: $boardParts,
                          boardSize: $boardSize,
                          connections: $connections,
                          onPartLongPressed: handlePartLongPressed,
                          outputFixed: false)
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
            }
        }
        .alert("Add Part", isPresented: $showAddConfirmation, actions: {
            Button("Cancel", role: .cancel) { selectedPartName = nil }
            Button("Add") {
                if let partName = selectedPartName {
                    let center = CGPoint(x: boardSize.width / 2, y: boardSize.height / 2)
                    let initialSignal = partName == "input signal" ? 1 : 0 // 输入信号默认 1
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
        }
        .navigationTitle("Free Play Mode")
    }

    // MARK: - Logic Functions

    private func handlePartLongPressed(_ part: Part) {
        longPressedPart = part
        showActionSheet = true
    }

    private func handleConnect(for part: Part) {
        if connectionSourcePart == nil {
            if part.imageName == "output signal" {
                return // 输出信号不能作为源
            } else {
                pendingTargetPart = part
                showSetSourceAlert = true
            }
        } else if connectionSourcePart!.id != part.id {
            if part.imageName == "input signal" {
                return // 输入信号不能作为目标
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
        // 重置所有非输入信号的部件信号
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
                    // OR: 有一个输入为 1 则输出 1
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.contains(1) ? 1 : 0

                case "nor gate":
                    // NOR: 所有输入为 0 则输出 1，否则输出 0
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.allSatisfy { $0 == 0 } ? 1 : 0

                case "and gate":
                    // AND: 所有输入为 1 则输出 1，否则输出 0
                    let inputs = connections.filter { $0.target == targetPart.id }
                    let inputSignals = inputs.compactMap { conn in
                        boardParts.first(where: { $0.id == conn.source })?.signal
                    }
                    boardParts[targetIndex].signal = inputSignals.allSatisfy { $0 == 1 } ? 1 : 0

                case "nand gate":
                    // NAND: 所有输入为 1 则输出 0，否则输出 1
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
}

// MARK: - Preview
struct FreePlayView_Previews: PreviewProvider {
    static var previews: some View {
        FreePlayView()
    }
}
