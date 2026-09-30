//
//  ComponentGuideView.swift
//  
//
//  Created by NewtTheBoy on 2/22/25.
//

//
//  ComponentGuideView.swift
//  CircuitCraft
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

// MARK: - 部件介绍视图
struct ComponentGuideView: View {
    // 定义所有部件的介绍页面
    private let componentPages: [TutorialPage] = [
        TutorialPage(
            imageName: "input signal", 
            title: "Input Signal",
            description: "The Input Signal provides the starting point for your circuit. It outputs a fixed value of 0 or 1, which you can set. Use it to drive logic gates or connect to outputs."
        ),
        TutorialPage(
            imageName: "output signal",
            title: "Output Signal",
            description: "The Output Signal receives and displays the result of your circuit. It takes the signal from its source and shows the final value (0 or 1). Connect it to gates to see the outcome."
        ),
        TutorialPage(
            imageName: "or gate",
            title: "OR Gate",
            description: "The OR Gate outputs 1 if at least one of its inputs is 1; otherwise, it outputs 0. It’s great for combining signals where any true input is enough."
        ),
        TutorialPage(
            imageName: "nor gate",
            title: "NOR Gate",
            description: "The NOR Gate outputs 1 only if all inputs are 0; otherwise, it outputs 0. Think of it as an OR Gate with an inverted output—useful for negation."
        ),
        TutorialPage(
            imageName: "not gate",
            title: "NOT Gate",
            description: "The NOT Gate inverts its input: 0 becomes 1, and 1 becomes 0. It’s a simple way to flip a signal and is often used with other gates."
        ),
        TutorialPage(
            imageName: "and gate",
            title: "AND Gate",
            description: "The AND Gate outputs 1 only if all its inputs are 1; otherwise, it outputs 0. Use it when you need multiple conditions to be true."
        ),
        TutorialPage(
            imageName: "nand gate",
            title: "NAND Gate",
            description: "The NAND Gate outputs 0 only if all inputs are 1; otherwise, it outputs 1. It’s an AND Gate with an inverted output and is very versatile."
        )
    ]

    @State private var currentPageIndex: Int = 0

        var body: some View {
            VStack {
                // 标题
                Text("Component Guide")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 20)

                // 页面内容
                TabView(selection: $currentPageIndex) {
                    ForEach(componentPages.indices, id: \.self) { index in
                        VStack(spacing: 20) {
                            // 部件图片
                            Image(componentPages[index].imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .padding()

                            // 标题
                            Text(componentPages[index].title)
                                .font(.system(size: 24, weight: .semibold))

                            // 描述
                            Text(componentPages[index].description)
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 移除默认顶部指示器
                .frame(maxHeight: .infinity)

                // 仅保留底部页面指示器
                HStack {
                    ForEach(componentPages.indices, id: \.self) { index in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(currentPageIndex == index ? .blue : .gray)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("", displayMode: .inline)
        }
    }

// MARK: - Preview
struct ComponentGuideView_Previews: PreviewProvider {
    static var previews: some View {
        ComponentGuideView()
    }
}
