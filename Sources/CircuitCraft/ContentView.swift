import SwiftUI

// MARK: - 关卡数据模型
struct Level: Identifiable, Codable {
    let id = UUID()
    var name: String
    var isUnlocked: Bool
    var config: LevelConfig
}

struct LevelConfig: Codable {
    var levelNumber: Int
}

// MARK: - 根据传入的关卡返回对应的游戏视图
@ViewBuilder
func destinationView(for level: Level) -> some View {
    switch level.config.levelNumber {
    case 1:
        GameView_Level1()
    case 2:
        GameView_Level2()
    case 3:
        GameView_Level3()
    case 4:
        GameView_Level4()
    case 5:
        GameView_Level5()
    case 6:
        GameView_Level6()
    case 7:
        GameView_Level7()
    case 8:
        GameView_Level8()
    case 9:
        GameView_Level9()
    case 10:
        GameView_Level10()
    case 11:
        GameView_Level11()
    case 12:
        GameView_Level12()
    case 13:
        GameView_Level13()
    case 14:
        GameView_Level14()
    case 15:
        GameView_Level15()
    case 16:
        GameView_Level16()
    case 17:
        GameView_Level17()
    case 18:
        GameView_Level18()
    case 19:
        GameView_Level19()
    case 20:
        GameView_Level20()
    case 21:
        GameView_Level21()
    case 22:
        GameView_Level22()
    case 23:
        GameView_Level23()
    case 24:
        GameView_Level24()
    case 25:
        GameView_Level25()
    case 26:
        GameView_Level26()
    case 27:
        GameView_Level27()
    case 28:
        GameView_Level28()
    case 29:
        GameView_Level29()
    case 30:
        GameView_Level30()
    default:
        ContentView()
    }
}

// MARK: - 主界面 ContentView
struct ContentView: View {
    @EnvironmentObject var levelStore: LevelStore
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                let screenWidth = proxy.size.width
                
                // 调整布局参数以降低高度
                let spacingMultiplier: CGFloat = (horizontalSizeClass == .regular) ? 0.06 : 0.03
                let titleFontMultiplier: CGFloat = (horizontalSizeClass == .regular) ? 0.06 : 0.05
                let circleMultiplier: CGFloat = (horizontalSizeClass == .regular) ? 0.25 : 0.18
                let gameStartFontMultiplier: CGFloat = (horizontalSizeClass == .regular) ? 0.035 : 0.025
                let smallButtonMultiplier: CGFloat = (horizontalSizeClass == .regular) ? 0.15 : 0.12
                let smallButtonFontMultiplier: CGFloat = (horizontalSizeClass == .regular) ? 0.02 : 0.015
                
                VStack(spacing: screenWidth * spacingMultiplier) {
                    Text("Circuit Craft!")
                        .font(.system(size: screenWidth * titleFontMultiplier))
                        .fontWeight(.bold)
                    
                    // GAME START 按钮
                    NavigationLink(destination: LevelSelectionView(levels: $levelStore.levels)) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .frame(width: screenWidth * circleMultiplier,
                                       height: screenWidth * circleMultiplier)
                                .shadow(radius: 10)
                            Text("GAME START")
                                .font(.system(size: screenWidth * gameStartFontMultiplier))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 新增三个小按钮
                    HStack(spacing: screenWidth * spacingMultiplier * 1.5) {
                        NavigationLink(destination: FreePlayView()) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                    )
                                    .frame(width: screenWidth * smallButtonMultiplier,
                                           height: screenWidth * smallButtonMultiplier)
                                    .shadow(radius: 5)
                                Text("Circuit Lab")
                                    .font(.system(size: screenWidth * smallButtonFontMultiplier))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        NavigationLink(destination: ComponentGuideView()) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [Color.green, Color.teal]),
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                    )
                                    .frame(width: screenWidth * smallButtonMultiplier,
                                           height: screenWidth * smallButtonMultiplier)
                                    .shadow(radius: 5)
                                Text("Part Explorer")
                                    .font(.system(size: screenWidth * smallButtonFontMultiplier))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        NavigationLink(destination: CircuitTheoryView()) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [Color.red, Color.pink]),
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                    )
                                    .frame(width: screenWidth * smallButtonMultiplier,
                                           height: screenWidth * smallButtonMultiplier)
                                    .shadow(radius: 5)
                                Text("Logic Lessons")
                                    .font(.system(size: screenWidth * smallButtonFontMultiplier))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - 选择关卡的页面
struct LevelSelectionView: View {
    @Binding var levels: [Level]
    let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5) // 每行 5 个
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 前 15 个关卡：建立电路
                VStack(spacing: 10) {
                    Text("Circuit Builder")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(levels.prefix(15)) { level in
                            NavigationLink(destination: destinationView(for: level)) {
                                LevelCell(level: level, isBuilder: true)
                            }
                            .disabled(!level.isUnlocked)
                        }
                    }
                }
                
                // 后 15 个关卡：分析电路
                VStack(spacing: 10) {
                    Text("Logic Analyzer")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(levels.dropFirst(15)) { level in
                            NavigationLink(destination: destinationView(for: level)) {
                                LevelCell(level: level, isBuilder: false)
                            }
                            .disabled(!level.isUnlocked)
                        }
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select a Level")
                    .font(.system(size: 30, weight: .bold))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 单个关卡显示组件
struct LevelCell: View {
    var level: Level
    var isBuilder: Bool // 区分建立和分析
    
    var body: some View {
        GeometryReader { geo in
            let cellWidth = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: cellWidth * 0.1)
                    .fill(level.isUnlocked
                          ? (isBuilder ? Color.blue.opacity(0.7) : Color.orange.opacity(0.7))
                          : Color.gray.opacity(0.5))
                VStack {
                    Text(level.name)
                        .font(.system(size: cellWidth * 0.2))
                        .foregroundColor(.white)
                    if !level.isUnlocked {
                        Text("Locked")
                            .font(.system(size: cellWidth * 0.15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .shadow(radius: 5)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LevelStore())
    }
}
