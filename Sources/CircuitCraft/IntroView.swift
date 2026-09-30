import SwiftUI

struct IntroView: View {
    @Binding var showIntro: Bool // 用于退出引导页面
    @State private var currentPage = 0 // 当前页索引

    var body: some View {
        VStack {
            // 内容区域
            TabView(selection: $currentPage) {
                // 第1页：欢迎页面
                VStack {
                    Text("Welcome to CircuitCraft")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                    Text("This is a game about circuits.")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer().frame(height: 20)
                    Text("You can explore and design freely,\n but first, let us introduce \nhow this works.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .tag(0)
                
                // 第2页：功能页面
                VStack {
                    Text("Explore freely")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    Text("Design circuits using logical gates, wires, and components.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .tag(1)
                
                // 第3页：结束页面
                VStack {
                    Text("Let’s Get Started!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    Text("Dive into the world of CircuitCraft and unleash your creativity!")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        showIntro = false // 完成引导，返回主界面
                    }) {
                        Text("Start Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // 隐藏圆点指示器
            .background(Color.white) // 设置整个 TabView 的背景为白色
            
            // 自定义左右箭头
            HStack {
                Button(action: {
                    if currentPage > 0 {
                        currentPage -= 1 // 上一页
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                        .foregroundColor(currentPage > 0 ? .blue : .gray) // 禁用时变灰
                }
                .disabled(currentPage == 0) // 禁用上一页按钮
                
                Spacer()
                
                Button(action: {
                    if currentPage < 2 {
                        currentPage += 1 // 下一页
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24))
                        .foregroundColor(currentPage < 2 ? .blue : .gray) // 禁用时变灰
                }
                .disabled(currentPage == 2) // 禁用下一页按钮
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
        .background(Color.white) // 设置整个页面的背景为白色
        .edgesIgnoringSafeArea(.all) // 确保背景覆盖整个屏幕
    }
}

// MARK: - Preview
struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView(showIntro: .constant(true))
    }
}
