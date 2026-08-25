---
name: init-get-cli
description: "Use when get_cli command is not found or needs installation for GetX scaffolding. Triggers on 'get_cli not found', 'install get_cli', 'init get cli'."
---

# GetX CLI

Flutter GetX 框架的代码生成工具，用于快速创建页面、控制器等脚手架代码。

## 安装

```bash
# 从 git 源安装（官方推荐）
dart pub global activate -s git https://github.com/jonataslaw/get_cli

# 验证
get_cli --version
```

如果提示找不到命令，确保 `$HOME/.pub-cache/bin` 在 PATH 中。

## 常用命令

| 命令 | 说明 |
|------|------|
| `get create page:名称` | 创建页面（view + controller + binding） |
| `get create controller:名称` | 创建控制器 |
| `get init` | 在现有项目初始化 GetX 结构 |
