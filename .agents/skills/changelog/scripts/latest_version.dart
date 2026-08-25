#!/usr/bin/env dart
/// 从 CHANGELOG.md 读取最新版本号。
///
/// 用法: dart run latest_version.dart [changelog_path]

import 'dart:io';

import 'package:project_workspace/project_workspace.dart';

import 'lib/changelog_parser.dart';

void main(List<String> arguments) {
  final changelogPath = arguments.isNotEmpty
      ? arguments[0]
      : '${getWorkspaceRoot(Platform.script.toFilePath()).path}/CHANGELOG.md';

  final parser = ChangelogParser.load(changelogPath);
  final version = parser.latestVersion();

  if (version == null) {
    logger.e('CHANGELOG.md 中未找到版本条目');
    exit(1);
  }

  print(version);
}
