---
name: changelog
description: Read and parse CHANGELOG.md for version info and release notes. Use when user asks about latest version, version history, release notes, or changelog content. Triggers on "latest version", "changelog", "release notes", "version log".
---

# Changelog 工具

解析 CHANGELOG.md 获取版本号和版本日志。

## 获取最新版本号

```bash
dart run <skill_path>/scripts/latest_version.dart [changelog_path]
```

输出最新版本号（如 `0.3.0`），适合用于自动化脚本。

## 获取特定版本日志

```bash
dart run <skill_path>/scripts/version_log.dart [version] [changelog_path]
```

不指定版本时默认输出最新版本的日志。输出完整日志内容（保留原始格式），适合用于 Release Notes。

## 参数说明

- `changelog_path`（可选）：CHANGELOG.md 路径，默认为工作区根目录下的 CHANGELOG.md
- `version`（必填）：要查询的版本号（如 `0.3.0`，不含 `v` 前缀）
