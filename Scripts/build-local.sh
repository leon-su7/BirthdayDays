#!/bin/bash
# 独立生成并构建工程，不使用 Apple 开发团队、签名证书或公证服务。
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${BIRTHDAY_CONFIGURATION:-Debug}"
BUILD_ARCHS="${BIRTHDAY_ARCHS:-$(uname -m)}"
case "${1:-}" in
    ""|--unsigned) ;;
    *) echo "用法：$0 [--unsigned]" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
    echo "用法：$0 [--unsigned]" >&2
    exit 2
fi
case "$CONFIGURATION" in
    Debug|Release) ;;
    *) echo "BIRTHDAY_CONFIGURATION 只支持 Debug 或 Release。" >&2; exit 2 ;;
esac
command -v xcodegen >/dev/null 2>&1 || {
    echo "缺少 XcodeGen，请先执行 brew install xcodegen。" >&2
    exit 1
}

# 所有路径以脚本位置为准，单独克隆及从任意工作目录调用均可构建。
xcodegen generate --spec "$PROJECT_DIR/project.yml"
xcodebuild -project "$PROJECT_DIR/BirthdayDays.xcodeproj" \
    -scheme BirthdayDays -configuration "$CONFIGURATION" -destination 'platform=macOS' \
    -derivedDataPath "$PROJECT_DIR/.build/DerivedData" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEVELOPMENT_TEAM= \
    "ARCHS=$BUILD_ARCHS" ONLY_ACTIVE_ARCH=NO build
echo "构建完成：$PROJECT_DIR/.build/DerivedData/Build/Products/$CONFIGURATION/诞生记录.app"
