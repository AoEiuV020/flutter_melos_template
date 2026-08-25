#!/bin/sh
# 从 CHANGELOG.md 读取最新版本号
# 用法: latest_version.sh [changelog_path]
set -e

CHANGELOG="${1:-CHANGELOG.md}"

if [ ! -f "$CHANGELOG" ]; then
  echo "CHANGELOG.md 未找到: $CHANGELOG" >&2
  exit 1
fi

grep -m1 '^## ' "$CHANGELOG" | sed 's/^## //'
