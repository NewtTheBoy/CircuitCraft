//
//  TutorialOverlayView.swift
//  CircuitCraft
//
//  Created by NewtTheBoy on 2/9/25.
//

import SwiftUI

import SwiftUI

struct TutorialOverlayView: View {
    @Binding var isPresented: Bool   // Controls whether the overlay is shown
    let pages: [TutorialPage]         // Tutorial data for multiple pages
    @State private var currentPage: Int = 0

    var body: some View {
        ZStack {
            // Semi-transparent background covering the entire screen
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Floating card
            VStack(spacing: 20) {
                ZStack {
                    // TabView for paging through tutorial pages (without default page dots)
                    TabView(selection: $currentPage) {
                        ForEach(pages.indices, id: \.self) { index in
                            VStack(spacing: 16) {
                                // Image section – adjust height as needed
                                Image(pages[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                
                                // Title
                                Text(pages[index].title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                // Scrollable description with extra bottom padding to prevent clipping
                                ScrollView {
                                    Text(pages[index].description)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 20) // Extra padding at the bottom of the text
                                }
                                .frame(height: 80)  // Increased height for the description area
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 250)  // Increased overall TabView height
                        
                    // Left/right arrow buttons overlayed on the TabView
                    HStack {
                        Button(action: {
                            withAnimation {
                                if currentPage > 0 { currentPage -= 1 }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title)
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .disabled(currentPage == 0)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                if currentPage < pages.count - 1 { currentPage += 1 }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title)
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .disabled(currentPage == pages.count - 1)
                    }
                    .padding(.horizontal, 16)
                }
                
                // "Got it!" button – add bottom padding so the button doesn't stick to the card's bottom edge
                Button(action: {
                    isPresented = false
                }) {
                    Text("Got it!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(20)
            .frame(maxWidth: 600)  // Adjust the maximum width for landscape/iPad screens
            .shadow(radius: 10)
        }
    }
}
