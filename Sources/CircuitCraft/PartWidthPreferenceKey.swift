//
//  PartWidthPreferenceKey.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

struct PartSizePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGSize] = [:]
    
    static func reduce(value: inout [UUID: CGSize], nextValue: () -> [UUID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
