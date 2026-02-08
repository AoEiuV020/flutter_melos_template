import 'dart:io';

import 'package:path/path.dart' as path;

import 'command.dart';
import 'module_setup.dart';

/// Create a Dart or Flutter package.
Future<bool> createPackage(
  String name,
  Directory workspaceRoot, {
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

  print('✅ Created package: ${modulePath.path}');
  return true;
}
