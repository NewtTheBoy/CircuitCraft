import SwiftUI

struct OrientationCheckView: View {
    @StateObject private var orientationManager = OrientationManager() // 管理方向
    @AppStorage("showIntro") private var showIntro = true // 是否显示引导页

    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            if orientationManager.isLandscape {
                // 横屏时根据状态显示引导页或主界面
                if showIntro {
                    IntroView(showIntro: $showIntro)
                } else {
                    ContentView()
                }
            } else {
                // 竖屏时显示提示
                VStack {
                    // 提示图标
                    Image(systemName: "rotate.left.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    // 提示文本
                    VStack {
                        Text("Please rotate your device")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 5)
                        Text("to landscape mode.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.red.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(40)
            }
        }
        .animation(.easeInOut, value: orientationManager.isLandscape) // 动画
    }
}
