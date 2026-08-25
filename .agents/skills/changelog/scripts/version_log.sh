#!/bin/sh
# 从 CHANGELOG.md 读取特定版本的日志（包含标题行）
# 用法: version_log.sh [version] [changelog_path]
# 不指定版本时默认读取最新版本
set -e

CHANGELOG="${2:-CHANGELOG.md}"

if [ ! -f "$CHANGELOG" ]; then
  echo "CHANGELOG.md 未找到: $CHANGELOG" >&2
  exit 1
fi

if [ -n "$1" ]; then
  VERSION="$1"
else
  VERSION=$(grep -m1 '^## ' "$CHANGELOG" | sed 's/^## //')
fi

if [ -z "$VERSION" ]; then
  echo "CHANGELOG.md 中未找到版本条目" >&2
  exit 1
fi

awk "/^## ${VERSION}\$/{found=1} /^## /&&!/^## ${VERSION}\$/{if(found)exit} found" "$CHANGELOG"
