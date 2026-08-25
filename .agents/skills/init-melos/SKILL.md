---
name: init-melos
description: "Use when melos command is not found or workspace needs initialization. Triggers on 'melos not found', 'install melos', 'melos bootstrap'."
---

# Melos CLI

Dart/Flutter monorepo 管理工具，用于管理多包工作区的依赖、脚本和发布。

## 安装

```bash
dart pub global activate melos

# 验证
melos --version
```

如果提示找不到命令，确保 `$HOME/.pub-cache/bin` 在 PATH 中。

## 初始化工作区

```bash
# 解析依赖并链接本地包
melos bootstrap
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `melos bootstrap` | 安装依赖并链接本地包 |
| `melos run <脚本名>` | 执行 pubspec.yaml 中定义的 melos 脚本 |
| `melos list` | 列出工作区内所有包 |
| `melos exec -- <命令>` | 在所有包中执行命令 |

具体脚本定义见根目录 `pubspec.yaml` 的 `melos.scripts` 部分。详细用法参考 `melos-guide` skill。
