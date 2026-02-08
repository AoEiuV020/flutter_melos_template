enum LogLevel { debug, info, warning, error }

void log(String message, {LogLevel level = LogLevel.info}) {
  final prefix = '[${_getLevelName(level)}]';
  print('$prefix $message');
}

String _getLevelName(LogLevel level) {
  switch (level) {
    case LogLevel.debug:
      return '调试';
    case LogLevel.info:
      return '信息';
    case LogLevel.warning:
      return '警告';
    case LogLevel.error:
      return '错误';
  }
}
