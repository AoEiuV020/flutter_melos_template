import 'dart:io';

import 'package:path/path.dart' as path;

import 'path_utils.dart';

/// 从脚本路径获取工作区根目录。
/// 脚本位于 `<工作区>/.claude/skills/<技能>/scripts/`。
Directory getWorkspaceRoot(String scriptPath) {
  final scriptDir = path.dirname(scriptPath);
  return normalizeAbsoluteDirectory(
    path.join(scriptDir, '..', '..', '..', '..'),
  );
}
