---
name: flutter-third-party-lib
description: "**Must use before adding any new Flutter/Dart dependency.** Use when adding a new package to pubspec.yaml, using an unfamiliar library, or when code uses a third-party API incorrectly. Triggers on 'add dependency', 'new package', 'pub.dev', 'third-party lib', or any pubspec.yaml dependency addition."
---

# Flutter Third-Party Library Usage Flow

添加任何新的 Flutter/Dart 第三方依赖前，必须先从 pub.dev 学习并编写用法文档，再根据文档编写代码。

## 强制流程

```
发现需要新依赖
    ↓
1. 从 pub.dev 查阅官方文档
    ↓
2. 记录本项目会用到的用法要点
    ↓
3. 根据要点编写/修改代码
```

**禁止跳过任何步骤。禁止凭记忆或猜测使用 API。**

## 从 pub.dev 学习

使用 `web_fetch` 工具访问 `https://pub.dev/packages/{包名}` 获取：

| 必须确认 | 说明 |
|----------|------|
| API 签名 | 构造函数参数、方法签名、返回类型 |
| 平台支持 | 各平台是否支持、是否有差异行为 |
| 必要配置 | 权限、entitlements、AndroidManifest 等 |
| 版本约束 | 当前稳定版本 |

**不要假设 API 用法。** 例如 `Logger()` 构造函数是否需要参数、`FilePicker.saveFile` 在不同平台行为是否一致，都必须从官方文档确认。

## 记录用法要点

按长期记忆的相关规则，记录本项目实际会用到的用法要点，供后续编码和复用参考，至少应覆盖：

| 要点 | 说明 |
|------|------|
| 本项目实际使用的 API | 只记会用到的部分，不抄全部 API |
| 平台行为差异 | 各平台是否支持、行为是否一致 |
| 必要配置 | 权限、entitlements、清单文件声明等 |
| 关键约束和注意事项 | 容易踩坑或与直觉不符的地方 |

## 根据要点编码

- 代码中的 API 调用必须与已确认的用法一致
- 发现实际行为与之前确认的用法不符时，先更新认知再继续编码
- 遇到未确认过的用法时，先查阅官方文档确认再写代码

## 红线

- ❌ 凭记忆猜测 API 用法
- ❌ 跳过官方文档确认直接写代码
- ❌ 从其他项目复制用法而不核实是否适用于本项目
