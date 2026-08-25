#!/usr/bin/env dart
/// 为 Melos 工作区中的 Flutter 应用创建 GitHub Actions 工作流。
///
/// 用法:
///     dart run create_workflow.dart <应用路径> [--name <工作流名称>]
///
/// 示例:
///     dart run create_workflow.dart apps/my_app
///     dart run create_workflow.dart apps/my_app --name ci.yml

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:project_workspace/project_workspace.dart';

/// 从模板创建工作流文件。
File createWorkflow(
  String appPath, {
  String workflowName = 'main',
  required Directory workspaceRoot,
  required Directory scriptDir,
}) {
  // 规范化应用路径
  appPath = appPath.replaceAll(RegExp(r'/+$'), '');
  if (!appPath.startsWith('apps/') && !appPath.startsWith('packages/')) {
    // 假设在 apps/ 下
    if (!appPath.contains('/')) {
      appPath = 'apps/$appPath';
    }
  }

  // 检查应用是否存在
  final fullAppPath = Directory(path.join(workspaceRoot.path, appPath));
  if (!fullAppPath.existsSync()) {
    logger.e('应用路径不存在: ${fullAppPath.path}');
    exit(1);
  }

  // 定位模板
  final templatePath = File(
    path.join(scriptDir.parent.path, 'assets', 'main.yml.template'),
  );

  if (!templatePath.existsSync()) {
    logger.e('模板未找到: ${templatePath.path}');
    exit(1);
  }

  // 读取模板
  var content = templatePath.readAsStringSync();

  // 替换占位符为应用路径
  content = content.replaceAll('apps/__APP_NAME__', appPath);

  // 创建 .github/workflows 目录
  final workflowsDir = Directory(
    path.join(workspaceRoot.path, '.github', 'workflows'),
  );
  if (!workflowsDir.existsSync()) {
    workflowsDir.createSync(recursive: true);
  }

  // 确保工作流名称有 .yml 扩展名
  if (!workflowName.endsWith('.yml') && !workflowName.endsWith('.yaml')) {
    workflowName = '$workflowName.yml';
  }

  // 写入工作流文件
  final outputPath = File(path.join(workflowsDir.path, workflowName));
  outputPath.writeAsStringSync(content);

  logger.i('✅ 已创建工作流: ${outputPath.path}');
  logger.i('   应用路径: $appPath');
  return outputPath;
}

void main(List<String> arguments) {

  final parser = ArgParser()
    ..addOption(
      'name',
      abbr: 'n',
      help: '工作流文件名（默认: main）',
      defaultsTo: 'main',
    )
    ..addOption(
      'workspace',
      abbr: 'w',
      help: '工作区根目录路径（未指定则自动检测）',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: '显示帮助信息',
      negatable: false,
    );

  ArgResults args;
  List<String> rest;
  try {
    args = parser.parse(arguments);
    rest = args.rest;
  } catch (e) {
    print('错误: $e\n');
    print('用法: dart run create_workflow.dart <应用路径> [选项]');
    print('');
    print(parser.usage);
    exit(1);
  }

  if (args['help'] as bool || rest.isEmpty) {
    print('为 Flutter 应用创建 GitHub Actions 工作流');
    print('');
    print('用法: dart run create_workflow.dart <应用路径> [选项]');
    print('');
    print('示例:');
    print('  dart run create_workflow.dart apps/my_app');
    print('  dart run create_workflow.dart apps/my_app --name ci');
    print('');
    print('选项:');
    print(parser.usage);
    exit(args['help'] as bool ? 0 : 1);
  }

  final appPath = rest.first;
  final workflowName = args['name'] as String;
  final scriptPath = Platform.script.toFilePath();
  final scriptDir = Directory(path.dirname(scriptPath));
  final workspaceRoot = resolveWorkspace(args, scriptPath);

  createWorkflow(
    appPath,
    workflowName: workflowName,
    workspaceRoot: workspaceRoot,
    scriptDir: scriptDir,
  );
}
