#!/bin/bash
# 兼容旧入口；当前构建默认无需开发团队和签名证书。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/build-local.sh" "$@"
