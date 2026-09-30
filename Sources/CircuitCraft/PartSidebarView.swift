//
//  PartSidebarView.swift
//  Template
//
//  Created by NewtTheBoy on 2/4/25.
//
import SwiftUI

struct PartsSidebarView: View {
    let availableParts: [String]
    let onPartTapped: (String) -> Void
    
    // Detect horizontal size class (e.g., .compact for iPhone, .regular for iPad)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        // Adjust values based on size class.
        let imageHeight: CGFloat = horizontalSizeClass == .regular ? 80 : 50
        let fontSize: CGFloat = horizontalSizeClass == .regular ? 20 : 12
        let paddingValue: CGFloat = horizontalSizeClass == .regular ? 12 : 8
        let frameWidth: CGFloat = horizontalSizeClass == .regular ? 120 : 80
        
        // Wrap the content in an HStack so we can add a Spacer on the trailing side.
        HStack(spacing: 0) {
            ScrollView {
                VStack {
                    ForEach(availableParts, id: \.self) { partName in
                        VStack(spacing: 4) {
                            Image(partName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: imageHeight)
                                .padding(paddingValue)
                                .onTapGesture {
                                    onPartTapped(partName)
                                }
                            Text(partName)
                                .font(.system(size: fontSize))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(width: frameWidth)
            .background(Color(white: 0.9))
            .cornerRadius(10)
            .shadow(radius: 5)
            
            // Add a Spacer to ensure space between the sidebar and the screen's right edge.
            Spacer(minLength: 20)
        }
        // Also add trailing padding on the entire HStack.
        .padding(.trailing, 40)
    }
}



