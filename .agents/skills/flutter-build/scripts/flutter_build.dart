import 'dart:io';

/// Flutter 编译结果。
class BuildResult {
  final int exitCode;
  final String output;

  const BuildResult({required this.exitCode, required this.output});

  /// 编译是否成功。
  bool get isSuccess => exitCode == 0;
}

/// 根据当前操作系统返回 Flutter 编译目标平台。
String detectPlatform() {
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  throw UnsupportedError('不支持的操作系统: ${Platform.operatingSystem}');
}

/// 执行 `flutter build` 并捕获完整输出。
Future<BuildResult> runFlutterBuild({
  required String appPath,
  String? platform,
  String mode = '--debug',
}) async {
  final targetPlatform = platform ?? detectPlatform();

  final result = await Process.run(
    'flutter',
    ['build', targetPlatform, mode],
    workingDirectory: appPath,
    runInShell: Platform.isWindows,
  );

  final output = StringBuffer()
    ..write(result.stdout)
    ..write(result.stderr);

  return BuildResult(
    exitCode: result.exitCode,
    output: output.toString(),
  );
}
