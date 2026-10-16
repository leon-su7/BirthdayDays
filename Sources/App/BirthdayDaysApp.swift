import SwiftUI
import WidgetKit
import os

/// 应用入口，负责承载生日天数的主窗口。
@main
struct BirthdayDaysApp: App {
    @NSApplicationDelegateAdaptor(BirthdayAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("诞生记录") {
            BirthdayRootView()
                .frame(minWidth: 740, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 780)
        .windowResizability(.contentMinSize)
    }
}

/// 安装维护入口只重载小组件，不创建主窗口或修改生日数据。
@MainActor
final class BirthdayAppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(subsystem: "local.birthday.app", category: "lifecycle")
    private let isWidgetRefresh = CommandLine.arguments.contains("--reload-widgets")

    /// 启动后请求系统重新读取组件快照，并等待请求发送后退出维护进程。
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isWidgetRefresh else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: "BirthdayDaysWidget")
        Self.logger.info("已请求重载生日小组件")
        Task { @MainActor in
            // 刷新通过系统服务异步处理，不在发出请求的同一轮运行循环中退出。
            try? await Task.sleep(for: .seconds(1))
            NSApplication.shared.terminate(nil)
        }
    }

    /// 维护模式禁止 SwiftUI 自动展示主窗口，常规启动仍按原场景运行。
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        !isWidgetRefresh
    }
}
