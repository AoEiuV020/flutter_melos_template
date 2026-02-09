import 'dart:io';

import 'log.dart';

/// 执行命令并返回是否成功。
Future<bool> runCommand(
  List<String> cmd, {
  String? workingDirectory,
  bool verbose = false,
}) async {
  try {
    if (verbose) {
      logger.i('正在执行: ${cmd.join(' ')}');
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
    logger.e('执行命令出错: $e');
    return false;
  }
}

/// 执行命令并返回裁剪后的标准输出。失败时返回 `null`。
Future<String?> runCommandOutput(
  List<String> cmd, {
  String? workingDirectory,
  bool verbose = false,
}) async {
  try {
    if (verbose) {
      logger.i('正在执行: ${cmd.join(' ')}');
    }
    final result = await Process.run(
      cmd.first,
      cmd.skip(1).toList(),
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      logger.e('${result.stderr}');
      return null;
    }
    return result.stdout.toString().trimRight();
  } catch (e) {
    logger.e('执行命令出错: $e');
    return null;
  }
}
