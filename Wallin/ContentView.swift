import Cocoa
import SwiftUI
import ServiceManagement
import AppKit
// WindowDelegate class removed as per refactoring instructions
struct WallpaperResponse: Decodable {
    let url: String
    let filename: String
}

struct ContentView: View {
    @State private var leftImage: NSImage?
    @State private var centerImage: NSImage?
    @State private var rightImage: NSImage?
    @State private var centerImageUrl: URL?
    @State private var rightImageUrl: URL?
    @State private var isLoading = true
    @State private var error: String?
    @State private var centerImageData: Data?
    @State private var rightImageData: Data?
    @State private var leftImageData: Data?
    @State private var nextButtonClickTimestamps: [Date] = []
    @State private var recentFilenames: [String] = []
    @State private var shouldAutoApplyWallpaper = false
    
    @AppStorage("wallpaperRefreshInterval") private var wallpaperRefreshInterval: Double = 0
    @AppStorage("lastWallpaperFetchTime") private var lastWallpaperFetchTime: Double = 0
    @AppStorage("wallinLanguage") private var wallinLanguage: String = "zh-Hans"
    @AppStorage("autoChangeOnLaunch") private var autoChangeOnLaunch: Bool = true


    var isNextButtonEnabled: Bool {
        let now = Date()
        let validClicks = nextButtonClickTimestamps.filter { now.timeIntervalSince($0) < 30 }
        return validClicks.count < 20
    }

    var body: some View {
        ZStack {
            if let background = centerImage {
                Image(nsImage: background)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 380)
                    .clipped()
                    .blur(radius: 20)
                    .opacity(0.3)
            }

            VStack(spacing: 15) {
                 Text("Wallin 壁纸")
                     .font(.title3)
                     .padding(.top)

                if isLoading || leftImage == nil || centerImage == nil || rightImage == nil {
                    VStack {
                        ProgressView()
                    }
                } else if let left = leftImage, let center = centerImage, let right = rightImage {
                    VStack(spacing: 15) {
                        // Text("Wallin 壁纸")
                        //     .font(.title2)
                        //     .fontWeight(.medium)
                        //     .padding(.top, 4)
                        
                        HStack(spacing: -20) {
                            // Left image
                            Image(nsImage: left)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 200)
                                .cornerRadius(16)
                                .shadow(radius: 5)

                            // Center image (larger, on top)
                            Image(nsImage: center)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 300)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                                .zIndex(1)

                            // Right image
                            Image(nsImage: right)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 200)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                        }

                        if #available(macOS 12.0, *) {
                            HStack(spacing: 10) {
                                Menu {
                                    Button("关于 Wallin") {
                                        DispatchQueue.main.async {
                                            let alert = NSAlert()
                                            alert.messageText = "关于 Wallin壁纸"
                                            alert.informativeText = """
版本 1.0
由 夏向 打造的 macOS 壁纸应用

图片来源包括 Bing、Unsplash、wallhaven 等公共图库平台，使用遵循平台开放协议。

 - 免责声明 -
本应用所展示的壁纸内容来源于公开图片接口，所有版权归原作者所有。
如有侵权请联系删除。
电子邮件：992625380@qq.com
"""
                                            alert.addButton(withTitle: "访问官网")
                                            alert.addButton(withTitle: "关闭")
                                            let response = alert.runModal()
                                            if response == .alertFirstButtonReturn {
                                                if let url = URL(string: "https://wallin.litgame.ac.cn") {
                                                    NSWorkspace.shared.open(url)
                                                }
                                            }
                                        }
                                    }
                                    Menu("自动更换壁纸") {
                                    Button("每6小时") {
                                            wallpaperRefreshInterval = 6 * 60 * 60
                                            DispatchQueue.main.async {
                                                let alert = NSAlert()
                                                alert.messageText = "已设置"
                                                alert.informativeText = "将每6小时自动更换一次壁纸"
                                                alert.runModal()
                                            }
                                        }
                                        Button("每12小时") {
                                            wallpaperRefreshInterval = 12 * 60 * 60
                                            DispatchQueue.main.async {
                                                let alert = NSAlert()
                                                alert.messageText = "已设置"
                                                alert.informativeText = "将每12小时自动更换一次壁纸"
                                                alert.runModal()
                                            }
                                        }
                                        Button("关闭定时更换壁纸") {
                                            wallpaperRefreshInterval = 0
                                            DispatchQueue.main.async {
                                                let alert = NSAlert()
                                                alert.messageText = "已关闭"
                                                alert.informativeText = "已关闭定时更换壁纸功能"
                                                alert.runModal()
                                            }
                                        }
                                        Toggle("启动App自动更换壁纸", isOn: $autoChangeOnLaunch)
                                    }
                                    Button("开机启动") {
                                        DispatchQueue.global(qos: .default).async {
                                            do {
                                                if #available(macOS 13.0, *) {
                                                    try SMAppService.mainApp.register()
                                                } else {
                                                    // Fallback on earlier versions
                                                }
                                                DispatchQueue.main.async {
                                                    let alert = NSAlert()
                                                    alert.messageText = "已设置开机启动"
                                                    alert.informativeText = "将在登录时自动启动，并更换壁纸🎉。  如需取消，可在【⚙️系统设置>通用>登录项】中将 Wallin 移除"
                                                    alert.runModal()
                                                }
                                            } catch {
                                                DispatchQueue.main.async {
                                                    let alert = NSAlert()
                                                    alert.messageText = "设置失败"
                                                    alert.informativeText = "无法设置开机启动：\(error.localizedDescription)"
                                                    alert.runModal()
                                                }
                                            }
                                        }
                                    }
                                    Button("查看本地缓存图片") {
                                        let folder = FileManager.default.temporaryDirectory
                                        NSWorkspace.shared.open(folder)
                                        closeWindow()  // 关闭窗口
                                    }
                                    /*
                                     Menu("语言设置") {
                                     Button("简体中文") {
                                     wallinLanguage = "zh-Hans"
                                     }
                                     Button("繁體中文") {
                                     wallinLanguage = "zh-Hant"
                                     }
                                     Button("English") {
                                     wallinLanguage = "en"
                                     }
                                     Button("日本語") {
                                     wallinLanguage = "ja"
                                     }
                                     Button("한국어") {
                                     wallinLanguage = "ko"
                                     }
                                     }
                                     */
                                    Divider()
                                    Button("退出应用") {
                                        NSApp.terminate(nil)
                                    }
                                } label: {
                                    HStack(spacing: 2) {
                                        Image(systemName: "gearshape")
                                            .imageScale(.medium)
                                        Text("设置")
                                    }
                                    .padding(.horizontal, 6)
                                }
                                .menuStyle(.borderedButton)
                                
                                Button("🖥️用作壁纸") {
                                    if let url = centerImageUrl {
                                        setAsDesktopWallpaper(url: url)
                                    }
                                }
                                
                                Button("🎉下一张") {
                                    let now = Date()
                                    nextButtonClickTimestamps = nextButtonClickTimestamps.filter { now.timeIntervalSince($0) < 30 }
                                    if nextButtonClickTimestamps.count >= 20 {
                                        DispatchQueue.main.async {
                                            let alert = NSAlert()
                                            alert.messageText = "加载新壁纸中～"
                                            alert.informativeText = "请稍后再试"
                                            alert.runModal()
                                        }
                                        return
                                    }
                                    nextButtonClickTimestamps.append(now)
                                    
                                    withAnimation {
                                        leftImage = centerImage
                                        centerImage = rightImage
                                        centerImageUrl = rightImageUrl
                                    }
                                    centerImageData = rightImageData
                                    fetchNewRightImage()
                                }
                                .disabled(!isNextButtonEnabled || rightImage == nil)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                } else if let error = error {
                    Text("出错了：\(error)")
                        .foregroundColor(.red)
                }

                Spacer()
            }
        }
        .frame(width: 300, height: 380)
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) {
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    if !window.styleMask.contains(.titled) {
                        window.styleMask.insert(.titled)
                    }
                    window.orderFront(nil)
                }
            }
            fetchWallpaper()
        }
        .onChange(of: shouldAutoApplyWallpaper) { newValue in
            if newValue, let url = centerImageUrl {
                setAsDesktopWallpaper(url: url)
                DispatchQueue.main.async {
                    shouldAutoApplyWallpaper = false
                }
            }
        }
    }

    func closeWindow() {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }

    func cachedImageURL(for url: URL) -> URL {
        let filename = url.lastPathComponent
        return FileManager.default.temporaryDirectory.appendingPathComponent("wallin_cache_\(filename)")
    }

    func fetchWallpaper() {
        isLoading = true
        error = nil

        guard let apiUrl = URL(string: "https://api.litgame.ac.cn/wallpaper?count=2") else {
            error = "API 地址无效"
            return
        }

        URLSession.shared.dataTask(with: apiUrl) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false

                if let err = err {
                    error = err.localizedDescription
                    return
                }

                guard let data = data else {
                    error = "没有收到数据"
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode([String: [WallpaperResponse]].self, from: data)
                    guard let images = decoded["images"], images.count == 2,
                          let imageURL1 = URL(string: images[0].url),
                          let imageURL2 = URL(string: images[1].url) else {
                        error = "未找到有效的两张图片地址"
                        return
                    }

                    self.centerImageUrl = imageURL1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        let cacheURL = cachedImageURL(for: imageURL1)
                        if !FileManager.default.fileExists(atPath: cacheURL.path) {
                            URLSession.shared.dataTask(with: imageURL1) { data, _, _ in
                                if let data = data {
                                    try? data.write(to: cacheURL)
                                    DispatchQueue.main.async {
                                        if autoChangeOnLaunch {
                                            setAsDesktopWallpaper(url: imageURL1)
                                        }
                                    }
                                }
                            }.resume()
                        } else {
                            if autoChangeOnLaunch {
                                setAsDesktopWallpaper(url: imageURL1)
                            }
                        }
                    }
                    self.rightImageUrl = imageURL2

                    loadLeftImage(from: imageURL1)
                    loadCenterImage(from: imageURL1)
                    loadNewRightImage(from: imageURL2)

                } catch {
                    self.error = "解析 JSON 出错"
                }
            }
        }.resume()
    }

    func loadLeftImage(from url: URL) {
        let cacheURL = cachedImageURL(for: url)
        if let data = try? Data(contentsOf: cacheURL), let nsImage = NSImage(data: data) {
            DispatchQueue.main.async {
                self.leftImage = nsImage
                self.leftImageData = data
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let nsImage = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.leftImage = nsImage
                    self.leftImageData = data
                }
            }
        }.resume()
    }

    func loadCenterImage(from url: URL) {
        let cacheURL = cachedImageURL(for: url)
        if let data = try? Data(contentsOf: cacheURL), let nsImage = NSImage(data: data) {
            self.centerImage = nsImage
            self.centerImageData = data
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let nsImage = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.centerImage = nsImage
                    self.centerImageData = data
                }
            }
        }.resume()
    }

    func fetchNewRightImage() {
        guard let apiUrl = URL(string: "https://api.litgame.ac.cn/wallpaper?count=1") else {
            return
        }

        URLSession.shared.dataTask(with: apiUrl) { data, _, err in
            if err != nil || data == nil {
                return
            }

            do {
                let decoded = try JSONDecoder().decode([String: [WallpaperResponse]].self, from: data!)
                guard let images = decoded["images"], let first = images.first,
                      let imageURL = URL(string: first.url) else {
                    return
                }
                DispatchQueue.main.async {
                    self.rightImageUrl = imageURL
                }
                loadNewRightImage(from: imageURL)
            } catch {
                print("右图 JSON 解码失败：\(error.localizedDescription)")
            }
        }.resume()
    }

    func loadNewRightImage(from url: URL) {
        let cacheURL = cachedImageURL(for: url)
        if let data = try? Data(contentsOf: cacheURL), let nsImage = NSImage(data: data) {
            DispatchQueue.main.async {
                self.rightImage = nsImage
                self.rightImageData = data
            }
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let nsImage = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.rightImage = nsImage
                    self.rightImageData = data
                }
            }
        }.resume()
    }

    func setAsDesktopWallpaper(url: URL) {
    print("🎯 尝试设置壁纸：\(url)")
    guard let screen = NSScreen.main else { return }
    if let data = centerImageData {
        let cacheURL = cachedImageURL(for: url)
        do {
            try data.write(to: cacheURL)
            print("✅ 图片已写入缓存：\(cacheURL.path)")
            let options: [NSWorkspace.DesktopImageOptionKey : Any] = [:]
            try NSWorkspace.shared.setDesktopImageURL(cacheURL, for: screen, options: options)
            print("✅ 壁纸设置成功")
            // 自动关闭窗口并弹出状态栏气泡提示词
            if autoChangeOnLaunch {
                if let window = NSApplication.shared.windows.first {
                    print("✅ 找到窗口（不再依赖 keyWindow），准备关闭")
                    window.close()

                    if let button = StatusBarController.shared?.statusItem.button {
                        let popover = NSPopover()
                        let popoverView = NSHostingView(rootView:
                            VStack(spacing: 6) {
                                Text("🎉 壁纸设置成功")
                                    .font(.headline)
                                Text("Wallin 已为你更换桌面壁纸")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()                  // 添加内边距（默认所有方向）
                            .frame(width: 200)          // 设置视图的固定宽度为 200（高度未设定）
                            .background(Color(NSColor.windowBackgroundColor))    // 背景颜色设置为系统色
                            .cornerRadius(12)           // 圆角半径设置为 12，视图边缘变圆润
                            .shadow(radius: 6)          // 添加阴影，阴影扩散半径为 6
                        )
                        popover.contentSize = NSSize(width: 160, height: 50)
                        popover.behavior = .transient
                        popover.contentViewController = NSViewController()
                        popover.contentViewController?.view = popoverView
                        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            popover.performClose(nil)
                        }
                    }
                } else {
                    print("❌ 没有找到任何窗口，无法关闭窗口")
                }
            }
        } catch {
            print("设置壁纸失败：\(error)")
        }
    }
    }
}
