import 'dart:io';

import 'package:path/path.dart' as path;

import 'command.dart';
import 'module_setup.dart';
import 'workspace.dart';

/// Create a Flutter FFI plugin.
Future<bool> createFfi(
  String name,
  Directory workspaceRoot, {
  List<String>? platforms,
  List<String>? extraArgs,
}) async {
  final packagesDir = ensureDir(path.join(workspaceRoot.path, 'packages'));
  final org = getOrganization(workspaceRoot);
  final modulePath = Directory(path.join(packagesDir.path, name));

  const defaultPlatforms = ['android', 'ios', 'windows', 'macos', 'linux'];
  platforms ??= defaultPlatforms;

  removePlatformDirs(Directory(packagesDir.path));

  final cmd = [
    'flutter',
    'create',
    '--org',
    org,
    '--template=plugin_ffi',
    '--platforms',
    platforms.join(','),
    name,
    ...?extraArgs,
  ];

  if (!await runCommand(cmd, workingDirectory: packagesDir.path)) {
    return false;
  }

  finalizeModule(workspaceRoot, modulePath);

  print('✅ Created FFI plugin: ${modulePath.path}');
  return true;
}
