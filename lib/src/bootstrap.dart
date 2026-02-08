import 'dart:io';

/// Run melos bootstrap to update dependencies.
Future<bool> runBootstrap(Directory workspaceRoot) async {
  print('Running melos bootstrap...');
  final result = await Process.run(
    'melos',
    ['bootstrap'],
    workingDirectory: workspaceRoot.path,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    print('Warning: melos bootstrap failed: ${result.stderr}');
    return false;
  }
  print('✅ melos bootstrap completed');
  return true;
}
