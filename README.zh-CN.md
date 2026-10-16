# 诞生记录

[English](README.md) · [简体中文](README.zh-CN.md)

<img src="Sources/App/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" alt="诞生记录应用图标" width="128" />

每一天，都算数。

一款使用 SwiftUI 与 WidgetKit 编写的 macOS 生日记录应用。以深绿与薄荷绿的时间刻度，呈现来到世界后的每一天。

## 功能

- 记录生日，查看已度过的自然天数、周岁和下次生日倒计时。
- 用环形与线性刻度展示本次生日到下次生日的年度进度。
- 可设置 1–150 岁的预计寿命，并选择显示结束倒计时，默认关闭。
- 修改设置时即时预览，保存后写入本机存储。
- 二月二十九日生日在非闰年按二月最后一天计算；日期计算考虑闰年与夏令时。
- 包含小、中、大三种 WidgetKit 小组件源码，使用限制见下文。
- 支持简体中文与英文，文字、日期、辅助功能说明及应用显示名称跟随系统语言。
- 无需账号或服务器。

## 下载安装

从 [Releases](https://github.com/leon-su7/BirthdayDays/releases) 下载 DMG 后，打开镜像并将“诞生记录”拖入 Applications。系统要求 macOS 14 或更新版本，安装包同时包含 Apple Silicon 与 Intel 架构。

安装包未使用 Apple 开发团队证书签名，也未公证，因此首次运行可能被 macOS 门禁拦截。请确认来源和校验文件，具体处理方式参考 [Apple 官方说明](https://support.apple.com/zh-cn/102445)。

```bash
shasum -a 256 -c BirthdayDays-1.0-universal.dmg.sha256
```

请将 DMG 与校验文件放在同一目录，并按下载版本调整文件名。

## 构建与打包

需要 macOS、Xcode 16 或更新版本，以及 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。先完成 Xcode 首次启动和命令行工具配置，再执行：

```bash
git clone https://github.com/leon-su7/BirthdayDays.git
cd BirthdayDays
brew install xcodegen
./Scripts/build-local.sh
open .build/DerivedData/Build/Products/Debug/诞生记录.app
```

默认构建不需要开发团队、证书、Apple 账号或公证凭据。打包通用架构的 Release 版本：

```bash
./Scripts/package-dmg.sh
```

产物位于 `dist/`，包含 `BirthdayDays-1.0-universal.dmg` 和对应的 `.sha256` 文件。脚本自动构建、生成只读压缩镜像并验证镜像完整性。GitHub Actions 使用同一入口生成可下载的构建产物。

也可先运行 `xcodegen generate`，再打开 `BirthdayDays.xcodeproj`。生成的工程不纳入版本控制，工程设置以 `project.yml` 为准。

Apple Silicon 可执行文件可能包含系统链接器自动生成的本地临时签名；这不是开发团队证书签名，构建及打包脚本不会调用 `codesign` 或公证服务。

## 小组件与数据共享限制

WidgetKit 小组件和 App Group 共享容器依赖 macOS 的签名与权限校验。默认的无开发者签名安装包以主应用为使用入口，不保证桌面小组件能够加载或与主应用同步；共享组不可用时，主应用自动回退到本机 UserDefaults，并显示“小组件同步暂不可用”。

仓库保留完整小组件源码。若自行配置签名，需要为主应用与扩展选择同一个开发团队、启用签名，并同步配置两个目标的 App Group 权限。共享组标识在 `project.yml` 中定义。

## 语言

界面自动跟随 macOS 的首选语言。也可在“系统设置 → 通用 → 语言与地区 → 应用程序”中为本应用单独选择简体中文或英文，重新启动后生效。主应用和小组件共用 `Resources/Localizable.xcstrings`，英文天数及年数支持单复数。

## 使用

打开应用，选择生日并点击“保存设置”。生日当天计为 0 天；清除生日会保留已保存的预计寿命和显示偏好。结束倒计时按出生日期加预计寿命计算，设定日期当天及之后显示 0 天，用于个人时间规划展示。

## 项目结构

```text
Sources/App/       SwiftUI 主窗口与应用图标
Sources/Widget/    WidgetKit 时间线与三种尺寸布局
Sources/Shared/    日期计算、存储、主题与 Lucide 图标
Support/           Info.plist 与沙盒权限
Scripts/           独立构建与 DMG 打包入口
project.yml        XcodeGen 工程定义
```

## 隐私与贡献

生日和显示偏好使用本机 UserDefaults 存储，源码不包含网络请求、分析 SDK 或广告 SDK。请勿在公开 Issue、截图或提交中包含真实生日、签名证书或其他个人信息。

欢迎通过 [Issues](https://github.com/leon-su7/BirthdayDays/issues) 反馈问题或提交 Pull Request。请说明系统版本、复现步骤与预期行为，提交前执行 `./Scripts/package-dmg.sh`。界面沿用现有深色主题，图标统一使用 Lucide。

## 许可证

项目使用 [MIT 许可证](LICENSE)。界面及应用图标中的 Lucide 路径保留原有 ISC / MIT 授权，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 与 [Lucide-LICENSE.txt](Sources/App/Lucide-LICENSE.txt)。
