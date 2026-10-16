首个开源版本，支持 macOS 14 及以上系统。

- 简体中文与英文界面、应用显示名称、日期和辅助功能说明，跟随 macOS 语言设置。
- 记录生命天数、周岁、生日年度进度与下次生日倒计时。
- 可选预计寿命与结束倒计时。
- 通用 DMG，同时支持 Apple Silicon 和 Intel，无需开发团队或证书。
- MIT 开源，保留 Lucide 授权。

下载下方 DMG，将应用拖入 Applications。安装包未使用 Apple 开发者证书签名或公证，首次打开可能受到系统门禁限制。桌面小组件和 App Group 同步依赖系统签名权限，无开发者签名版本不保证小组件可用。

将 DMG 与 `.sha256` 文件放在同一目录后校验：

```bash
shasum -a 256 -c BirthdayDays-1.0-universal.dmg.sha256
```

Birth Record is a native macOS birthday tracker with English and Simplified Chinese localization. The universal DMG supports Apple Silicon and Intel on macOS 14 or later. No Apple development team, certificate, or notarization is used. macOS may block the first launch; widgets and App Group sharing are not guaranteed without developer signing. See [README.en.md](https://github.com/leon-su7/BirthdayDays/blob/main/README.en.md) for build and usage instructions.
