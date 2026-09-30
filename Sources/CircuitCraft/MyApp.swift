import SwiftUI

@main
struct MyApp: App {
    @AppStorage("showIntro") private var showIntro = true // 是否显示引导页
    @StateObject private var levelStore = LevelStore()

    var body: some Scene {
        WindowGroup {
            OrientationCheckView() // 首先判断设备方向
                .environmentObject(levelStore)
        }
    }
}
