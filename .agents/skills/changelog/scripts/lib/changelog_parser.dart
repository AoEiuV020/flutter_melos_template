import 'dart:io';

/// 从 CHANGELOG.md 解析版本信息。
class ChangelogParser {
  final List<String> _lines;
  static final _versionPattern = RegExp(r'^## (?:\[)?(.+?)(?:\])?(?:\s|$)');

  ChangelogParser._(this._lines);

  /// 从文件路径加载。
  factory ChangelogParser.load(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('CHANGELOG.md 未找到: $path');
      exit(1);
    }
    return ChangelogParser._(file.readAsLinesSync());
  }

  /// 获取最新版本号。
  String? latestVersion() {
    for (final line in _lines) {
      final match = _versionPattern.firstMatch(line);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// 获取指定版本的完整日志（保留格式）。
  String? versionLog(String version) {
    final buffer = StringBuffer();
    var found = false;

    for (final line in _lines) {
      final match = _versionPattern.firstMatch(line);
      if (match != null) {
        if (found) break;
        if (match.group(1) == version) {
          found = true;
          buffer.writeln(line);
        }
      } else if (found) {
        buffer.writeln(line);
      }
    }

    return found ? buffer.toString().trimRight() : null;
  }
}
