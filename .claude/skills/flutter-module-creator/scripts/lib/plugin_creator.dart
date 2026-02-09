import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:project_workspace/project_workspace.dart';

/// 创建 Flutter 插件。
Future<bool> createPlugin(
  String name,
  Directory workspaceRoot,
  ProjectConfig config, {
  List<String>? platforms,
  List<String>? extraArgs,
}) async {
  final packagesDir = ensureDir(path.join(workspaceRoot.path, 'packages'));
  final modulePath = Directory(path.join(packagesDir.path, name));

  removePlatformDirs(Directory(packagesDir.path));

  final cmd = [
    'flutter',
    'create',
    '--org',
    config.org,
    '--template=plugin',
    name,
  ];
  if (platforms != null && platforms.isNotEmpty) {
    cmd.addAll(['--platforms', platforms.join(',')]);
  }
  if (extraArgs != null) {
    cmd.addAll(extraArgs);
  }

  if (!await runCommand(cmd, workingDirectory: packagesDir.path)) {
    return false;
  }

  finalizeModule(workspaceRoot, modulePath);

  logger.i('✅ 已创建插件: ${modulePath.path}');
  return true;
}
