#!/usr/bin/env dart

import 'dart:io';

import 'lib/workspace_updater.dart';

void main(List<String> arguments) {
  log('脚本启动，参数: $arguments');

  if (arguments.isEmpty) {
    log('用法: dart update_workspace.dart <root_path> [module_path]',
        level: LogLevel.error);
    exit(1);
  }

  final rootPath = arguments[0];
  final modulePath =
      arguments.length > 1 && arguments[1].isNotEmpty ? arguments[1] : null;

  log('根目录路径: $rootPath', level: LogLevel.debug);
  log('模块路径: $modulePath', level: LogLevel.debug);

  // 验证根目录存在
  if (!Directory(rootPath).existsSync()) {
    log('根目录不存在: $rootPath', level: LogLevel.error);
    exit(1);
  }

  // 更新子模块的 pubspec.yaml（如果提供了路径）
  if (modulePath != null) {
    // 验证模块目录存在
    if (!Directory(modulePath).existsSync()) {
      log('指定的模块目录不存在: $modulePath', level: LogLevel.error);
      exit(1);
    }
    log('开始更新模块 pubspec.yaml: $modulePath', level: LogLevel.info);
    updateModulePubspec(modulePath);
  }

  // 更新根目录的 pubspec.yaml
  log('开始更新根目录 pubspec.yaml: $rootPath', level: LogLevel.info);
  updateRootPubspec(rootPath, modulePath);

  log('脚本执行完成', level: LogLevel.info);
}
