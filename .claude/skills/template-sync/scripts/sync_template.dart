#!/usr/bin/env dart
/// 模板同步 — 将上游模板更新合并到派生项目中。
///
/// 用法: dart run sync_template.dart [--template <路径>] [选项]

import 'dart:io';

import 'package:args/args.dart';
import 'package:project_workspace/project_workspace.dart';

import 'lib/template_syncer.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('template',
        abbr: 't', help: '模板仓库路径（必填）')
    ..addOption('template-commit',
        abbr: 'c', help: '项目所基于的模板 commit SHA')
    ..addFlag('dry-run',
        help: '仅显示将执行的操作，不实际执行', negatable: false)
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

  if (args['help'] as bool) {
    print('将模板更改同步到当前项目。\n');
    print('用法: dart run sync_template.dart [--template <路径>] [选项]\n');
    print(parser.usage);
    exit(0);
  }

  final scriptPath = Platform.script.toFilePath();
  final workspaceRoot = getWorkspaceRoot(scriptPath);
  final projectPath = workspaceRoot.path;

  // 解析模板路径: --template 参数 > .env TEMPLATE_REPO
  String? templateArg = args['template'] as String?;
  if (templateArg == null) {
    final config = ProjectConfig(workspaceRoot);
    templateArg = config.templateRepo;
    if (templateArg == null) {
      print('错误: --template 是必填项（或在 .env 中设置 TEMPLATE_REPO）\n');
      print(parser.usage);
      exit(1);
    }
    logger.i('从 .env 读取模板路径: $templateArg');
  }

  final templatePath = Directory(templateArg).existsSync()
      ? Directory(templateArg).absolute.path
      : templateArg;

  await syncTemplate(
    projectPath: projectPath,
    templatePath: templatePath,
    templateCommitSha: args['template-commit'] as String?,
    dryRun: args['dry-run'] as bool,
  );
}
