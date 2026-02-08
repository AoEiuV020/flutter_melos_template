import 'dart:io';

import 'package:path/path.dart' as path;

import 'command.dart';
import 'module_setup.dart';
import 'workspace.dart';

/// Create a Flutter app or Dart console application.
Future<bool> createApp(
  String name,
  Directory workspaceRoot, {
  bool console = false,
  List<String>? extraArgs,
}) async {
  final appsDir = ensureDir(path.join(workspaceRoot.path, 'apps'));
  final org = getOrganization(workspaceRoot);
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
      org,
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

  print('✅ Created app: ${modulePath.path}');
  return true;
}
