import 'dart:io';

import 'log.dart';

/// Run a command and return success status.
Future<bool> runCommand(
  List<String> cmd, {
  String? workingDirectory,
  bool verbose = false,
}) async {
  try {
    if (verbose) {
      logger.i('Running: ${cmd.join(' ')}');
    }
    final result = await Process.run(
      cmd.first,
      cmd.skip(1).toList(),
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      logger.e('${result.stderr}');
      return false;
    }
    if (verbose && result.stdout.toString().isNotEmpty) {
      logger.i(result.stdout.toString().trimRight());
    }
    return true;
  } catch (e) {
    logger.e('Error running command: $e');
    return false;
  }
}
