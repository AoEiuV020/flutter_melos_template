import 'dart:io';

import 'log.dart';

/// 运行 melos bootstrap 更新依赖。
Future<bool> runBootstrap(Directory workspaceRoot) async {
  logger.i('正在运行 melos bootstrap...');
  final result = await Process.run(
    'melos',
    ['bootstrap'],
    workingDirectory: workspaceRoot.path,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    logger.w('melos bootstrap 失败: ${result.stderr}');
    return false;
  }
  logger.i('✅ melos bootstrap 完成');
  return true;
}
