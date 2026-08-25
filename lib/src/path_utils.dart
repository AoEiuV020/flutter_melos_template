import 'dart:io';

import 'package:path/path.dart' as path;

/// 将路径规范化为统一使用正斜杠的可移植路径。
String normalizePortablePath(String value) {
  return path.normalize(value).replaceAll('\\', '/');
}

/// 计算目标路径相对于基准目录的可移植路径。
String relativePortablePath(String target, {required String from}) {
  return normalizePortablePath(path.relative(target, from: from));
}

/// 将目录路径规范化为绝对路径。
Directory normalizeAbsoluteDirectory(String directory) {
  return Directory(path.normalize(path.absolute(directory)));
}
