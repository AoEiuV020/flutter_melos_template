---
name: flutter-test
description: "**Must use before running any test.** Use when executing tests, verifying changes, or checking test results."
---

# Running Tests

## Overview

melos monorepo 中测试分两层：**melos**（多包调度）和 **flutter test**（单包执行）。关键陷阱：`melos run test` 匹配多包时会弹交互选择，必须用 `--no-select` 跳过。

## Quick Reference

| 目标 | 命令 |
|------|------|
| 全部包全部测试 | `melos run test --no-select` |
| 指定包全部测试 | `melos run test --scope="pkg_name"` |
| 指定包指定文件 | `melos exec --scope="pkg_name" -- flutter test test/path_test.dart` |
| 指定包 name 过滤 | `melos exec --scope="pkg_name" -- flutter test --name="regex"` |
| 指定包 plain-name | `melos exec --scope="pkg_name" -- flutter test --plain-name="exact substring"` |
| 按 tag 过滤 | `melos exec --scope="pkg_name" -- flutter test --tags="tag_name"` |
| 首次失败即停 | 加 `--fail-fast` |
| 详细输出 | 加 `-r expanded` |

## melos 层

### `melos run <script>` — 执行 pubspec.yaml 中定义的脚本

关键参数：
- `--no-select`：跳过交互式包选择（**agent/CI 必加**）
- `--scope="glob"`：仅匹配包名的包

### `melos exec` — 在多包中执行任意命令

```bash
melos exec --scope="my_pkg" -- flutter test test/some_test.dart
```

- 命令写在 `--` 之后
- `--scope` 支持 glob 模式（如 `"my_*"`）
- `-c N`：并发数（默认 5）
- `--fail-fast`：任一包失败即停

### 其他有用 filter

| filter | 说明 |
|--------|------|
| `--scope="glob"` | 包名匹配 |
| `--ignore="glob"` | 排除包 |
| `--dir-exists=test` | 仅有 test 目录的包 |
| `--depends-on=pkg` | 仅依赖某包的包 |
| `--flutter` / `--no-flutter` | Flutter / 纯 Dart 包 |

## flutter test 层

在单个包目录下执行。

### 文件/目录筛选

```bash
flutter test test/models/           # 整个目录
flutter test test/foo_test.dart     # 单个文件
```

### name 过滤

```bash
flutter test --name="regex pattern"          # 正则匹配 test/group 名
flutter test --plain-name="exact substring"  # 纯文本子串匹配
```

可与文件参数组合：

```bash
flutter test test/foo_test.dart --name="边界"
```

### 常用参数

| 参数 | 说明 |
|------|------|
| `--name="regex"` | 正则匹配 test/group 名称 |
| `--plain-name="str"` | 纯文本子串匹配 |
| `--tags="tag"` | 按标签过滤 |
| `--exclude-tags="tag"` | 排除标签 |
| `--fail-fast` | 首次失败即停 |
| `--no-fail-fast` | 不停（默认） |
| `-r expanded` | 每个测试单独一行 |
| `-r failures-only` | 仅显示失败 |
| `--coverage` | 收集覆盖率 |
| `--no-pub` | 跳过 pub get |
| `--update-goldens` | 更新 golden 文件 |
| `-j N` | 并发进程数 |

## Common Mistakes

| 错误 | 正确做法 |
|------|---------|
| `melos run test` 卡住等输入 | 加 `--no-select` |
| `melos exec flutter test ...` | `--` 分隔：`melos exec -- flutter test ...` |
| 在 workspace root 直接 `flutter test` | 用 melos exec 或 cd 到具体包目录 |
| `--name` 当精确匹配用 | `--name` 是正则；精确匹配用 `--plain-name` |
