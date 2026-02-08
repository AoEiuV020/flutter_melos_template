import 'dart:io';

import 'log.dart';

/// Run melos bootstrap to update dependencies.
Future<bool> runBootstrap(Directory workspaceRoot) async {
  logger.i('Running melos bootstrap...');
  final result = await Process.run(
    'melos',
    ['bootstrap'],
    workingDirectory: workspaceRoot.path,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    logger.w('melos bootstrap failed: ${result.stderr}');
    return false;
  }
  logger.i('✅ melos bootstrap completed');
  return true;
}
