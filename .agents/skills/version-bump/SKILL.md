---
name: version-bump
description: 更新版本号和 CHANGELOG.md。当用户要求更新版本、发版、写更新日志时使用。Triggers on "更新版本", "bump version", "发版", "更新日志".
---

# Version Bump

更新应用版本号和 CHANGELOG.md。

## 步骤

### 1. 获取 CHANGELOG.md 上次修改以来的 git log

```bash
# 需拆开执行：$() 嵌套命令会被安全过滤器拦截
# readlink 解析 symlink，非 symlink 时 fallback 原路径
git --no-pager log --format=" - %s" $(git --no-pager log -1 --format=%H -- $(readlink CHANGELOG.md || echo CHANGELOG.md))..HEAD
```

### 2. 确定新版本号

根据变更内容决定版本号递增规则：

| 变更类型 | 版本递增 | 示例 |
|----------|----------|------|
| 破坏性变更 | major | 1.0.0 → 2.0.0 |
| 新功能 | minor | 1.0.0 → 1.1.0 |
| 修复/优化 | patch | 1.0.0 → 1.0.1 |

### 3. 编写更新日志

将 git log 归纳为简洁的用户可读条目：

- 用自然语言描述，不要带 `feat:`、`fix:` 等 commit 前缀
- 合并相关的多个 commit 为一条（如 probe 模型 + 服务 + 页面 → "支持查看视频详细信息"）
- 去掉内部模块细节（如 ffmpeg_kit、build_runner），只写用户可感知的功能
- 每条一句话，不超过 20 个字

### 4. 更新文件

| 文件 | 修改内容 |
|------|----------|
| `CHANGELOG.md` | 在顶部添加新版本段落 |
| 应用 `pubspec.yaml` | 更新 `version` 字段，build number +1 |

> `git add` 时使用步骤 1 中解析的真实路径，确保改动被正确暂存。

### 5. 提交并整理

```
chore: 更新版本至 <新版本号>
```

如果版本更新过程中有来回修改产生多余 commit，先 rebase 合并为一个再继续。

### 6. 添加 git tag

```bash
git tag v<新版本号>
```
