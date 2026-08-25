#!/usr/bin/env dart
/// 从 CHANGELOG.md 读取特定版本的日志。
///
/// 用法: dart run version_log.dart [version] [changelog_path]
/// 不指定版本时默认读取最新版本。

import 'dart:io';

import 'package:project_workspace/project_workspace.dart';

import 'lib/changelog_parser.dart';

void main(List<String> arguments) {
  final changelogPath = arguments.length > 1
      ? arguments[1]
      : '${getWorkspaceRoot(Platform.script.toFilePath()).path}/CHANGELOG.md';

  final parser = ChangelogParser.load(changelogPath);

  // 默认使用最新版本
  final version = arguments.isNotEmpty
      ? arguments[0]
      : parser.latestVersion();

  if (version == null) {
    logger.e('CHANGELOG.md 中未找到版本条目');
    exit(1);
  }

  final log = parser.versionLog(version);
  if (log == null) {
    logger.e('CHANGELOG.md 中未找到版本 $version');
    exit(1);
  }

  print(log);
}
