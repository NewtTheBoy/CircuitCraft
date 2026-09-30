//
//  CircuitTheoryView.swift
//  CircuitCraft
//
//  Created by [Your Name] on [Date]
//

import SwiftUI

// MARK: - Logic Lessons 视图（技巧版）
struct CircuitTheoryView: View {
    // 定义逻辑技巧页面
    private let theoryPages: [TutorialPage] = [
        TutorialPage(
            imageName: "analyze_icon", // 假设图片资源名
            title: "Analyze Inputs and Outputs",
            description: "Start by looking at the required outputs and available inputs. Match them step-by-step. For example, if you need a 0 from two 1s, think NAND (1 NAND 1 = 0). Test in Free Play to confirm your guess!"
        ),
        TutorialPage(
            imageName: "not_gate_icon",
            title: "Flip Signals with NOT",
            description: "Use a NOT gate to invert a signal when the output doesn’t match the input. Example: If a level needs a 0 but you have a 1, add a NOT gate after the input to flip it to 0."
        ),
        TutorialPage(
            imageName: "nand_nor_icon",
            title: "Master NAND and NOR Flexibility",
            description: "NAND and NOR can mimic other gates. Two NANDs in a row act like an AND (NAND + NAND = AND). A NOR with all 0s gives 1. Use them to simplify circuits when stuck!"
        ),
        TutorialPage(
            imageName: "step_by_step_icon",
            title: "Break Down Complex Circuits",
            description: "For multi-gate levels, work backwards from the output. Ask: 'What inputs make this gate output what I need?' Example: To get a 1 from NOR, all inputs must be 0—trace back to make it happen."
        ),
        TutorialPage(
            imageName: "multi_output_icon",
            title: "Handle Multiple Outputs",
            description: "When a level has multiple outputs, solve one at a time. Check each gate’s output against the goal. Example: If one output needs 1 and another 0, split inputs with OR and AND gates."
        )
    ]

    @State private var currentPageIndex: Int = 0

    var body: some View {
        VStack {
            // 标题
            Text("Logic Lessons")
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 20)

            // 页面内容
            TabView(selection: $currentPageIndex) {
                ForEach(theoryPages.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        // 示例图片
                        Image(theoryPages[index].imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200, maxHeight: 200)
                            .padding()

                        // 标题
                        Text(theoryPages[index].title)
                            .font(.system(size: 24, weight: .semibold))

                        // 描述
                        Text(theoryPages[index].description)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 移除顶部指示器
            .frame(maxHeight: .infinity)

            // 底部页面指示器
            HStack {
                ForEach(theoryPages.indices, id: \.self) { index in
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
struct CircuitTheoryView_Previews: PreviewProvider {
    static var previews: some View {
        CircuitTheoryView()
    }
}
