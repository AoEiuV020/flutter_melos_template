import 'dart:io';

import 'log.dart';

/// Add `resolution: workspace` to a module's pubspec.yaml.
void updateModulePubspec(String modulePath) {
  final pubspecFile = File('$modulePath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    logger.e('模块 pubspec.yaml 不存在: $modulePath/pubspec.yaml');
    exit(1);
  }

  logger.d('找到模块 pubspec.yaml: $modulePath');
  final content = pubspecFile.readAsStringSync();

  if (content.contains('resolution:')) {
    logger.i('模块已包含 resolution: workspace，跳过处理');
    return;
  }

  logger.d('向 $modulePath/pubspec.yaml 添加 resolution: workspace');
  final lines = content.split('\n');
  final updatedLines = <String>[];
  var environmentFound = false;
  var resolutionAdded = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    updatedLines.add(line);

    if (!resolutionAdded && line.trimLeft().startsWith('environment:')) {
      environmentFound = true;
      logger.d('在第 ${i + 1} 行找到 environment 节');
      final environmentIndent =
          line.substring(0, line.indexOf('environment:'));

      var j = i + 1;
      while (j < lines.length &&
          lines[j].trim().isNotEmpty &&
          (lines[j].startsWith('$environmentIndent  ') ||
              lines[j].trim().startsWith('#'))) {
        updatedLines.add(lines[j]);
        j++;
      }
      i = j - 1;

      updatedLines.add('');
      updatedLines.add('${environmentIndent}resolution: workspace');
      resolutionAdded = true;
      logger.d('添加 resolution: workspace 节');
    }
  }

  if (!environmentFound) {
    logger.e('$modulePath/pubspec.yaml 中未找到 environment 节');
    exit(1);
  }

  if (resolutionAdded) {
    pubspecFile.writeAsStringSync(updatedLines.join('\n'));
    logger.i('成功更新 $modulePath/pubspec.yaml，已添加 resolution: workspace');
  }
}

/// Update root pubspec.yaml workspace list, optionally adding a new module.
void updateRootPubspec(String rootPath, String? newModulePath) {
  final pubspecFile = File('$rootPath/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    logger.e('根目录 pubspec.yaml 不存在: $rootPath');
    exit(1);
  }

  logger.d('找到根目录 pubspec.yaml: $rootPath');
  final content = pubspecFile.readAsStringSync();
  final lines = content.split('\n');

  final workspaceSet = <String>{};
  var inWorkspaceSection = false;

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.trimLeft().startsWith('workspace:')) {
      inWorkspaceSection = true;
      logger.d('在第 ${index + 1} 行找到现有的 workspace 节');
      continue;
    }
    if (inWorkspaceSection) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        var path = trimmed.substring(2).trim();
        path = path.replaceAll('\\', '/');
        workspaceSet.add(path);
        logger.d('找到 workspace 条目: $path (已规范化)');
      } else if (trimmed.isNotEmpty && !line.startsWith('  ')) {
        inWorkspaceSection = false;
      }
    }
  }

  if (newModulePath != null) {
    var relativePath = newModulePath.startsWith(rootPath)
        ? newModulePath.substring(rootPath.length + 1)
        : newModulePath;
    relativePath = relativePath.replaceAll('\\', '/');
    if (workspaceSet.add(relativePath)) {
      logger.d('向 workspace 添加新模块: $relativePath');
    } else {
      logger.d('模块已存在于 workspace 中: $relativePath');
    }
  }

  final sortedWorkspace = workspaceSet.toList()..sort();
  logger.d('最终 workspace 条目: $sortedWorkspace');

  final updatedLines = <String>[];
  var environmentFound = false;
  var workspaceFound = false;
  var environmentIndent = '';
  var skipUntilNextSection = false;
  var fileChanged = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmedLine = line.trimLeft();

    if (trimmedLine.startsWith('workspace:')) {
      workspaceFound = true;
      skipUntilNextSection = true;
      logger.d('删除第 ${i + 1} 行的旧 workspace 节');
      fileChanged = true;
      continue;
    }

    if (skipUntilNextSection) {
      if (line.trim().isEmpty || trimmedLine.startsWith('- ')) {
        continue;
      } else if (!line.startsWith('  ') &&
          !line.startsWith('\t') &&
          line.trim().isNotEmpty) {
        skipUntilNextSection = false;
      } else {
        continue;
      }
    }

    if (trimmedLine.startsWith('environment:')) {
      environmentFound = true;
      environmentIndent = line.substring(0, line.indexOf('environment:'));
      logger.d('在第 ${i + 1} 行找到 environment 节，缩进: "${environmentIndent.replaceAll(' ', '·')}"');
      updatedLines.add(line);

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

      if (!workspaceFound && sortedWorkspace.isNotEmpty) {
        updatedLines.add('');
        updatedLines.add('${environmentIndent}workspace:');
        for (final path in sortedWorkspace) {
          updatedLines.add('$environmentIndent  - $path');
        }
        updatedLines.add('');
        workspaceFound = true;
        fileChanged = true;
        logger.d('在 environment 后添加 workspace 节');
      }
      continue;
    }

    updatedLines.add(line);
  }

  if (!environmentFound && sortedWorkspace.isNotEmpty) {
    logger.w('未找到 environment 节，将 workspace 添加到文件末尾');
    updatedLines.add('');
    updatedLines.add('workspace:');
    for (final path in sortedWorkspace) {
      updatedLines.add('  - $path');
    }
    workspaceFound = true;
    fileChanged = true;
  }

  if (fileChanged) {
    pubspecFile.writeAsStringSync(updatedLines.join('\n'));
    logger.i('成功更新根目录 pubspec.yaml');
    logger.i('workspace 条目已添加/更新: ${sortedWorkspace.join(", ")}');
  } else {
    logger.i('根目录 pubspec.yaml 无需修改');
  }
}

/// Register a module in the workspace (update both module and root pubspec).
void registerModule(Directory workspaceRoot, Directory modulePath) {
  updateModulePubspec(modulePath.path);
  updateRootPubspec(workspaceRoot.path, modulePath.path);
}
