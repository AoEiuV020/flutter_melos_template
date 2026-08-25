---
name: init-import-sorter
description: "Use when import_sorter is not found or Dart imports need sorting. Triggers on 'import_sorter not found', 'sort imports', 'install import_sorter'."
---

# Import Sorter

自动排序 Dart 文件的 import 语句。使用支持 pub workspaces 的修复版本。

## 安装

```bash
# 从修复分支安装（支持 monorepo pub workspaces）
dart pub global activate --source git https://github.com/myConsciousness/import_sorter.git --git-ref fix/monorepo-pub-workspaces

# 验证
dart pub global list | grep import_sorter
```

> **为什么用 fork？** 官方版本不支持 Dart pub workspaces，在 monorepo 中会报错。此分支修复了工作区解析问题。

## 使用

```bash
# 单个包内排序
dart pub global run import_sorter --no-comments

# 通过 melos 对所有包排序
melos sort
```

`--no-comments` 表示不在 import 分组之间插入注释。
