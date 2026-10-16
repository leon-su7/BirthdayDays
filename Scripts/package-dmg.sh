#!/bin/bash
# 构建适用于 Apple Silicon 与 Intel 的 DMG，不进行开发者签名和公证。
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export BIRTHDAY_CONFIGURATION=Release
export BIRTHDAY_ARCHS="arm64 x86_64"
"$PROJECT_DIR/Scripts/build-local.sh"

APP_BUNDLE="$PROJECT_DIR/.build/DerivedData/Build/Products/Release/诞生记录.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
OUTPUT_DIR="$PROJECT_DIR/dist"
mkdir -p "$OUTPUT_DIR"
STAGING_DIR="$(mktemp -d "$PROJECT_DIR/.build/dmg.XXXXXX")"
# 只清理本次创建的临时目录，脚本失败时也不留下打包中间产物。
trap 'rm -rf "$STAGING_DIR"' EXIT
ditto "$APP_BUNDLE" "$STAGING_DIR/诞生记录.app"
ln -s /Applications "$STAGING_DIR/Applications"
DMG_PATH="$OUTPUT_DIR/BirthdayDays-$VERSION-universal.dmg"
hdiutil create -volname "诞生记录" -srcfolder "$STAGING_DIR" \
    -format UDZO -ov "$DMG_PATH"
hdiutil verify "$DMG_PATH"
# 校验文件使用相对文件名，下载后可直接在同一目录执行 shasum -a 256 -c。
(cd "$OUTPUT_DIR" && shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$DMG_PATH").sha256")
echo "DMG 与 SHA-256 校验文件已生成：$DMG_PATH"
