import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:project_workspace/project_workspace.dart';

/// Create a Dart or Flutter package.
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

  logger.i('✅ Created package: ${modulePath.path}');
  return true;
}
