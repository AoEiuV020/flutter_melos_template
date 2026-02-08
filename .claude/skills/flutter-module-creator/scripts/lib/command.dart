import 'dart:io';

/// Run a command and return success status.
Future<bool> runCommand(
  List<String> cmd, {
  String? workingDirectory,
  bool verbose = false,
}) async {
  try {
    if (verbose) {
      print('Running: ${cmd.join(' ')}');
    }
    final result = await Process.run(
      cmd.first,
      cmd.skip(1).toList(),
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      print('Error: ${result.stderr}');
      return false;
    }
    if (verbose && result.stdout.toString().isNotEmpty) {
      print(result.stdout);
    }
    return true;
  } catch (e) {
    print('Error running command: $e');
    return false;
  }
}

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
