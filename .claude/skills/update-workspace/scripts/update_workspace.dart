#!/usr/bin/env dart

import 'dart:io';

// 日志级别
enum LogLevel { debug, info, warning, error }

// 封装的日志打印函数
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

void main(List<String> arguments) {
  log('脚本启动，参数: $arguments');

  if (arguments.isEmpty) {
    log('用法: dart update_workspace.dart <root_path> [module_path]',
        level: LogLevel.error);
    exit(1);
  }

  final rootPath = arguments[0];
  final modulePath =
      arguments.length > 1 && arguments[1].isNotEmpty ? arguments[1] : null;

  log('根目录路径: $rootPath', level: LogLevel.debug);
  log('模块路径: $modulePath', level: LogLevel.debug);

  // 验证根目录存在
  if (!Directory(rootPath).existsSync()) {
    log('根目录不存在: $rootPath', level: LogLevel.error);
    exit(1);
  }

  // 更新子模块的 pubspec.yaml（如果提供了路径）
  if (modulePath != null) {
    // 验证模块目录存在
    if (!Directory(modulePath).existsSync()) {
      log('指定的模块目录不存在: $modulePath', level: LogLevel.error);
      exit(1);
    }
    log('开始更新模块 pubspec.yaml: $modulePath', level: LogLevel.info);
    updateModulePubspec(modulePath);
  }

  // 更新根目录的 pubspec.yaml
  log('开始更新根目录 pubspec.yaml: $rootPath', level: LogLevel.info);
  updateRootPubspec(rootPath, modulePath);

  log('脚本执行完成', level: LogLevel.info);
}

void updateModulePubspec(String modulePath) {
  final pubspecFile = File('$modulePath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    log('模块 pubspec.yaml 不存在: $modulePath/pubspec.yaml', level: LogLevel.error);
    exit(1);
  }

  log('找到模块 pubspec.yaml: $modulePath', level: LogLevel.debug);
  final content = pubspecFile.readAsStringSync();

  // 检查是否已存在 resolution
  if (content.contains('resolution:')) {
    log('模块已包含 resolution: workspace，跳过处理', level: LogLevel.info);
    return;
  }

  log('向 $modulePath/pubspec.yaml 添加 resolution: workspace',
      level: LogLevel.debug);
  final lines = content.split('\n');
  final updatedLines = <String>[];
  var environmentFound = false;
  var resolutionAdded = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    updatedLines.add(line);

    // 找到 environment 节
    if (!resolutionAdded && line.trimLeft().startsWith('environment:')) {
      environmentFound = true;
      log('在第 ${i + 1} 行找到 environment 节', level: LogLevel.debug);
      final environmentIndent = line.substring(0, line.indexOf('environment:'));

      // 跳过 environment 的内容
      var j = i + 1;
      while (j < lines.length &&
          lines[j].trim().isNotEmpty &&
          (lines[j].startsWith('$environmentIndent  ') ||
              lines[j].trim().startsWith('#'))) {
        updatedLines.add(lines[j]);
        j++;
      }
      i = j - 1;

      // 添加空行和 resolution
      updatedLines.add('');
      updatedLines.add('${environmentIndent}resolution: workspace');
      resolutionAdded = true;
      log('添加 resolution: workspace 节', level: LogLevel.debug);
    }
  }

  // 如果没找到 environment
  if (!environmentFound) {
    log('$modulePath/pubspec.yaml 中未找到 environment 节', level: LogLevel.error);
    exit(1);
  }

  if (resolutionAdded) {
    pubspecFile.writeAsStringSync(updatedLines.join('\n'));
    log('成功更新 $modulePath/pubspec.yaml，已添加 resolution: workspace',
        level: LogLevel.info);
  }
}

void updateRootPubspec(String rootPath, String? newModulePath) {
  final pubspecFile = File('$rootPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    log('根目录 pubspec.yaml 不存在: $rootPath', level: LogLevel.error);
    exit(1);
  }

  log('找到根目录 pubspec.yaml: $rootPath', level: LogLevel.debug);
  final content = pubspecFile.readAsStringSync();
  final lines = content.split('\n');

  // 解析现有的 workspace 条目
  final workspaceSet = <String>{};
  var inWorkspaceSection = false;

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.trimLeft().startsWith('workspace:')) {
      inWorkspaceSection = true;
      log('在第 ${index + 1} 行找到现有的 workspace 节', level: LogLevel.debug);
      continue;
    }
    if (inWorkspaceSection) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        var path = trimmed.substring(2).trim();
        // 规范化路径分隔符，统一使用正斜杠
        path = path.replaceAll('\\', '/');
        workspaceSet.add(path);
        log('找到 workspace 条目: $path (已规范化)', level: LogLevel.debug);
      } else if (!trimmed.isEmpty && !line.startsWith('  ')) {
        inWorkspaceSection = false;
      }
    }
  }

  // 添加新模块（如果提供）
  if (newModulePath != null) {
    // 转换为相对于根目录的路径
    var relativePath = newModulePath.startsWith(rootPath)
        ? newModulePath.substring(rootPath.length + 1)
        : newModulePath;
    // 确保使用正斜杠作为分隔符
    relativePath = relativePath.replaceAll('\\', '/');
    if (workspaceSet.add(relativePath)) {
      log('向 workspace 添加新模块: $relativePath', level: LogLevel.debug);
    } else {
      log('模块已存在于 workspace 中: $relativePath', level: LogLevel.debug);
    }
  }

  // 排序
  final sortedWorkspace = workspaceSet.toList()..sort();
  log('最终 workspace 条目: $sortedWorkspace', level: LogLevel.debug);

  // 重建 pubspec.yaml
  final updatedLines = <String>[];
  var environmentFound = false;
  var workspaceFound = false;
  var environmentIndent = '';
  var skipUntilNextSection = false;
  var fileChanged = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmedLine = line.trimLeft();

    // 跳过旧的 workspace 块
    if (trimmedLine.startsWith('workspace:')) {
      workspaceFound = true;
      skipUntilNextSection = true;
      log('删除第 ${i + 1} 行的旧 workspace 节', level: LogLevel.debug);
      fileChanged = true;
      continue;
    }

    if (skipUntilNextSection) {
      // 如果是列表项或空行，继续跳过
      if (line.trim().isEmpty || trimmedLine.startsWith('- ')) {
        continue;
      } else if (!line.startsWith('  ') &&
          !line.startsWith('\t') &&
          line.trim().isNotEmpty) {
        // 遇到下一个顶级节，停止跳过
        skipUntilNextSection = false;
      } else {
        continue;
      }
    }

    // 找到 environment 节
    if (trimmedLine.startsWith('environment:')) {
      environmentFound = true;
      environmentIndent = line.substring(0, line.indexOf('environment:'));
      log('在第 ${i + 1} 行找到 environment 节，缩进: "${environmentIndent.replaceAll(' ', '·')}"',
          level: LogLevel.debug);
      updatedLines.add(line);

      // 添加 environment 的内容
      var j = i + 1;
      while (j < lines.length) {
        final nextLine = lines[j];
        if (nextLine.trim().isEmpty) {
          j++;
          continue;
        }
        if (nextLine.startsWith('$environmentIndent  ') ||
            nextLine.trim().startsWith('#')) {
          updatedLines.add(nextLine);
          j++;
        } else {
          break;
        }
      }
      i = j - 1;

      // 在 environment 后添加 workspace（如果还没有添加）
      if (!workspaceFound && sortedWorkspace.isNotEmpty) {
        updatedLines.add('');
        updatedLines.add('${environmentIndent}workspace:');
        for (final path in sortedWorkspace) {
          updatedLines.add('$environmentIndent  - $path');
        }
        updatedLines.add('');
        workspaceFound = true;
        fileChanged = true;
        log('在 environment 后添加 workspace 节', level: LogLevel.debug);
      }
      continue;
    }

    updatedLines.add(line);
  }

  // 如果没有找到 environment 但有 workspace 条目要添加，添加到末尾
  if (!environmentFound && sortedWorkspace.isNotEmpty) {
    log('未找到 environment 节，将 workspace 添加到文件末尾', level: LogLevel.warning);
    updatedLines.add('');
    updatedLines.add('workspace:');
    for (final path in sortedWorkspace) {
      updatedLines.add('  - $path');
    }
    workspaceFound = true;
    fileChanged = true;
  }

  // 检查是否需要写入文件
  if (fileChanged) {
    pubspecFile.writeAsStringSync(updatedLines.join('\n'));
    log('成功更新根目录 pubspec.yaml', level: LogLevel.info);
    log('workspace 条目已添加/更新: ${sortedWorkspace.join(", ")}',
        level: LogLevel.info);
  } else {
    log('根目录 pubspec.yaml 无需修改', level: LogLevel.info);
  }
}
