import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:project_workspace/project_workspace.dart';

/// 创建 Dart 或 Flutter 包。
Future<bool> createPackage(
  String name,
  Directory workspaceRoot,
  ProjectConfig config, {
  bool flutter = false,
  List<String>? extraArgs,
}) async {
  final packagesDir = ensureDir(path.join(workspaceRoot.path, 'packages'));
  final modulePath = Directory(path.join(packagesDir.path, name));

  final cmd = flutter
      ? ['flutter', 'create', '--template=package', name, ...?extraArgs]
      : ['dart', 'create', '--template=package', name, ...?extraArgs];

  if (!await runCommand(cmd, workingDirectory: packagesDir.path)) {
    return false;
  }

  finalizeModule(workspaceRoot, modulePath, useFlutter: flutter);

  logger.i('✅ 已创建包: ${modulePath.path}');
  return true;
}
