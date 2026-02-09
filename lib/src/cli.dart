import 'dart:io';

import 'package:args/args.dart';

import 'workspace.dart';

/// 验证所有必需选项是否存在。缺失时输出用法并退出。
void requireOptions(ArgResults args, ArgParser parser, List<String> required) {
  for (final name in required) {
    if (args[name] == null) {
      print('错误: --$name 是必填项。\n');
      print(parser.usage);
      exit(1);
    }
  }
}

/// 从 --workspace 参数或脚本路径解析工作区根目录。
Directory resolveWorkspace(ArgResults args, String scriptPath) {
  return args['workspace'] != null
      ? Directory(args['workspace'] as String)
      : getWorkspaceRoot(scriptPath);
}
