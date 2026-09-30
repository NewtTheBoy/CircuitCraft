//
//  LevelStore.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/9/25.
//

import SwiftUI
import Combine

class LevelStore: ObservableObject {
    @Published var levels: [Level] = [] {
        didSet {
            saveLevels()
        }
    }
    
    private let defaultsKey = "levelsKey"
    
    init() {
        loadLevels()
    }
    
    private func loadLevels() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decodedLevels = try? JSONDecoder().decode([Level].self, from: data) {
            self.levels = decodedLevels
        } else {
            // 初始化所有30关都解锁
            self.levels = (1...30).map { number in
                Level(name: "Level \(number)",
                      isUnlocked: true, // 所有关卡默认解锁
                      config: LevelConfig(levelNumber: number))
            }
        }
    }
    
    private func saveLevels() {
        if let encodedData = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(encodedData, forKey: defaultsKey)
        }
    }
}
