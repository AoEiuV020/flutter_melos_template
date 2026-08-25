/// 过滤 Flutter 编译输出，仅保留错误信息。
///
/// 成功时返回 `null`，失败时返回提取的错误摘要。
String? filterBuildOutput(String output, {required bool isSuccess}) {
  if (isSuccess) return null;

  final lines = output.split('\n');
  final errors = <String>[];
  var inErrorBlock = false;

  for (final line in lines) {
    if (line.contains(': Error: ')) {
      // Dart 编译错误行，如 lib/main.dart:13:1: Error: ...
      inErrorBlock = true;
      errors.add(line);
    } else if (inErrorBlock) {
      if (_isErrorContext(line)) {
        // 错误上下文：建议、代码片段、指示符号
        errors.add(line);
      } else {
        inErrorBlock = false;
      }
    }
  }

  if (errors.isEmpty) {
    // 没有匹配到标准 Dart 错误，返回最后几行作为兜底
    final tail = lines.where((l) => l.trim().isNotEmpty).toList();
    final start = (tail.length - 5).clamp(0, tail.length);
    return tail.sublist(start).join('\n');
  }

  return errors.join('\n');
}

/// 判断是否属于错误上下文行。
bool _isErrorContext(String line) {
  if (line.trim().isEmpty) return false;

  // 指示符号行，如 ^^^^^^^^^^^^^^^^^
  if (RegExp(r'^\s*\^+\s*$').hasMatch(line)) return true;

  // 建议行，通常以 "Try" 开头
  if (line.startsWith('Try ')) return true;

  // 代码片段行（不以特定前缀开头的普通文本）
  if (!line.startsWith('Target ') &&
      !line.startsWith('Failed ') &&
      !line.startsWith('Command ') &&
      !line.startsWith('**') &&
      !line.startsWith('Build ') &&
      !line.contains('Building ') &&
      !line.contains('Resolving ') &&
      !line.contains('Downloading ')) {
    return true;
  }

  return false;
}
