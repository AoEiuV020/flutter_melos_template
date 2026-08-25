#!/usr/bin/env dart
/// Flutter/Dart 模块创建器
///
/// 用法: dart run create_module.dart --type <类型> --name <名称> [选项]

import 'dart:io';

import 'package:args/args.dart';
import 'package:project_workspace/project_workspace.dart';

import 'lib/app_creator.dart';
import 'lib/ffi_creator.dart';
import 'lib/package_creator.dart';
import 'lib/plugin_creator.dart';

void main(List<String> arguments) async {

  final parser = ArgParser()
    ..addOption('type',
        abbr: 't',
        allowed: ['app', 'package', 'plugin', 'ffi'],
        help: '要创建的模块类型')
    ..addOption('name',
        abbr: 'n', help: '模块名称')
    ..addFlag('console',
        help: '创建 Dart 控制台应用而非 Flutter 应用（仅限 app 类型）',
        negatable: false)
    ..addFlag('flutter',
        help:
            '创建 Flutter 包而非 Dart 包（仅限 package 类型）',
        negatable: false)
    ..addOption('platforms',
        abbr: 'p',
        help:
            'plugin/ffi 的逗号分隔平台列表（例如 android,ios,macos）')
    ..addOption('workspace',
        abbr: 'w',
        help: '工作区根目录路径（未指定则自动检测）')
    ..addFlag('no-bootstrap',
        help: '创建后跳过 melos bootstrap', negatable: false)
    ..addFlag('help',
        abbr: 'h', help: '显示帮助信息', negatable: false);

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('错误: $e\n');
    print(parser.usage);
    exit(1);
  }

  if (args['help'] as bool || arguments.isEmpty) {
    print('Flutter/Dart 模块创建器\n');
    print(
        '用法: dart run create_module.dart --type <类型> --name <名称> [选项]\n');
    print(parser.usage);
    exit(arguments.isEmpty ? 1 : 0);
  }

  requireOptions(args, parser, ['type', 'name']);

  final scriptPath = Platform.script.toFilePath();
  final workspaceRoot = resolveWorkspace(args, scriptPath);
  final config = ProjectConfig(workspaceRoot);

  if (!File('${workspaceRoot.path}/pubspec.yaml').existsSync()) {
    logger.e(
        '工作区根目录未找到 pubspec.yaml: ${workspaceRoot.path}');
    exit(1);
  }

  logger.i('工作区根目录: ${workspaceRoot.path}');

  final platforms = args['platforms'] != null
      ? (args['platforms'] as String).split(',')
      : null;

  final success = switch (args['type'] as String) {
    'app' => await createApp(args['name'] as String, workspaceRoot, config,
        console: args['console'] as bool),
    'package' => await createPackage(
        args['name'] as String, workspaceRoot, config,
        flutter: args['flutter'] as bool),
    'plugin' => await createPlugin(
        args['name'] as String, workspaceRoot, config,
        platforms: platforms),
    'ffi' => await createFfi(args['name'] as String, workspaceRoot, config,
        platforms: platforms),
    _ => false,
  };

  if (!success) exit(1);

  if (!(args['no-bootstrap'] as bool)) {
    await runBootstrap(workspaceRoot);
  }

  logger.i("\n🎉 模块 '${args['name']}' 创建成功！");
}
