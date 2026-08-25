---
name: init-very-good
description: "Use when very_good command is not found or needs installation. Triggers on 'very_good not found', 'install very_good', 'very good cli'."
---

# Very Good CLI

Very Good Ventures 提供的 Flutter/Dart 项目工具，支持创建项目、生成代码等。

## 安装

```bash
dart pub global activate very_good_cli

# 验证
very_good --version
```

如果提示找不到命令，确保 `$HOME/.pub-cache/bin` 在 PATH 中。

## 常用命令

| 命令 | 说明 |
|------|------|
| `very_good create flutter_app <名称>` | 创建 Flutter 应用 |
| `very_good create dart_package <名称>` | 创建 Dart 包 |
| `very_good packages get` | 递归获取依赖 |
| `very_good test` | 运行测试并收集覆盖率 |
