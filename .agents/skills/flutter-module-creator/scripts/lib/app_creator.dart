import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:project_workspace/project_workspace.dart';

/// 创建 Flutter 应用或 Dart 控制台应用。
Future<bool> createApp(
  String name,
  Directory workspaceRoot,
  ProjectConfig config, {
  bool console = false,
  List<String>? extraArgs,
}) async {
  final appsDir = ensureDir(path.join(workspaceRoot.path, 'apps'));

  final modulePath = Directory(path.join(appsDir.path, name));

  if (console) {
    final cmd = ['dart', 'create', name, ...?extraArgs];
    if (!await runCommand(cmd, workingDirectory: appsDir.path)) {
      return false;
    }
    finalizeModule(workspaceRoot, modulePath,
        useFlutter: false, withLicense: false);
  } else {
    removePlatformDirs(Directory(appsDir.path));
    final cmd = [
      'flutter',
      'create',
      '--org',
      config.org,
      '--template=app',
      name,
      ...?extraArgs
    ];
    if (!await runCommand(cmd, workingDirectory: appsDir.path)) {
      return false;
    }
    finalizeModule(workspaceRoot, modulePath,
        useFlutter: true, withLicense: false);
  }

  logger.i('✅ 已创建应用: ${modulePath.path}');
  return true;
}
