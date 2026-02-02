---
name: flutter-style
description: Flutter/Dart coding style guide. **Must use before writing Flutter/Dart code.** Use when creating new files, refactoring code, or reviewing Flutter/Dart code quality.
---

# Flutter/Dart 编码规范

编写 Flutter/Dart 代码前必须遵循以下规范。

## 文件组织

### 一类一文件
- 每个类独立存放在单独文件中
- 文件名使用 snake_case，与类名对应
  - `DanmakuMessage` → `danmaku_message.dart`
  - `WebSocketClient` → `websocket_client.dart`
- 例外：枚举可与相关类合并；私有内部类可与外部类合并
- 使用 barrel 文件（如 `models.dart`）统一导出

### 目录结构
```
lib/
  src/
    models/       # 数据模型
    services/     # 服务类
    utils/        # 工具类
    widgets/      # UI 组件
```

## 导入顺序

1. Dart SDK 库
2. Flutter 框架库
3. 第三方包
4. 项目内部文件

## 类成员顺序

1. 静态常量
2. 静态变量
3. 实例变量
4. 构造函数
5. 静态方法
6. 实例方法
7. 私有方法

## 命名规范

| 类型 | 风格 | 示例 |
|------|------|------|
| 类名 | PascalCase | `WebSocketClient` |
| 文件名 | snake_case | `web_socket_client.dart` |
| 变量/方法 | camelCase | `sendMessage()` |
| 常量 | camelCase + const/final | `const maxRetries = 3` |
| 私有成员 | 前缀 `_` | `_connectionState` |

## 注释规范

- 公开 API 必须有文档注释（`///`）
- 复杂逻辑必须有行内注释（`//`）
- 标记：`TODO:`、`FIXME:`、`NOTE:`
