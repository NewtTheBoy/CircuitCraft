//
//  OrientationManager.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 11/18/24.
//

import UIKit
import Combine

public class OrientationManager: ObservableObject {
    @Published public var isLandscape: Bool = UIDevice.current.orientation.isLandscape
    
    public init() {
        // 初始化时检测方向
        let currentOrientation = UIDevice.current.orientation
        if currentOrientation == .unknown {
            isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        } else {
            isLandscape = currentOrientation.isLandscape
        }
        
        // 监听设备方向变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleOrientationChange() {
        let currentOrientation = UIDevice.current.orientation
        if currentOrientation == .unknown {
            isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        } else {
            isLandscape = currentOrientation.isLandscape
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
