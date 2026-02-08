#!/usr/bin/env dart

import 'dart:io';

import 'package:project_workspace/project_workspace.dart';

void main(List<String> arguments) {
  logger.i('脚本启动，参数: $arguments');

  if (arguments.isEmpty) {
    logger.e('用法: dart update_workspace.dart <root_path> [module_path]');
    exit(1);
  }

  final rootPath = arguments[0];
  final modulePath =
      arguments.length > 1 && arguments[1].isNotEmpty ? arguments[1] : null;

  logger.d('根目录路径: $rootPath');
  logger.d('模块路径: $modulePath');

  if (!Directory(rootPath).existsSync()) {
    logger.e('根目录不存在: $rootPath');
    exit(1);
  }

  if (modulePath != null) {
    if (!Directory(modulePath).existsSync()) {
      logger.e('指定的模块目录不存在: $modulePath');
      exit(1);
    }
    logger.i('开始更新模块 pubspec.yaml: $modulePath');
    updateModulePubspec(modulePath);
  }

  logger.i('开始更新根目录 pubspec.yaml: $rootPath');
  updateRootPubspec(rootPath, modulePath);

  logger.i('脚本执行完成');
}
