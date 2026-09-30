//
//  CircuitBoardBackground.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//

import SwiftUI

struct CircuitBoardBackground: View {
    var body: some View {
        GeometryReader { geometry in
            // Use the minimum of width and height to determine a base dimension.
            let minDimension = min(geometry.size.width, geometry.size.height)
            // Define grid spacing as a fraction of the min dimension.
            let gridSpacing: CGFloat = minDimension / 20  // Adjust as needed.
            // Dot diameter is set as a fraction of grid spacing.
            let dotDiameter: CGFloat = gridSpacing / 10    // Adjust as needed.
            
            Canvas { context, size in
                // Draw vertical grid lines.
                var x: CGFloat = 0.0
                while x <= size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.gray), lineWidth: 0.5)
                    x += gridSpacing
                }
                
                // Draw horizontal grid lines.
                var y: CGFloat = 0.0
                while y <= size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(.gray), lineWidth: 0.5)
                    y += gridSpacing
                }
                
                // Draw small dots at each grid intersection.
                x = 0.0
                while x <= size.width {
                    y = 0.0
                    while y <= size.height {
                        let dotRect = CGRect(
                            x: x - dotDiameter / 2,
                            y: y - dotDiameter / 2,
                            width: dotDiameter,
                            height: dotDiameter)
                        let dotPath = Path(ellipseIn: dotRect)
                        context.fill(dotPath, with: .color(.gray))
                        y += gridSpacing
                    }
                    x += gridSpacing
                }
            }
        }
        .ignoresSafeArea()
    }
}
