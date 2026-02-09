import 'dart:io';

import 'log.dart';

/// 从 git remote URL 获取 HTTPS 仓库地址。
/// 假设服务器和 GitHub 一样的 SSH/HTTPS 对应关系，支持任意 git 服务器。
/// 获取失败时返回 null。
String? _getGitHubRepoUrl(String workspacePath) {
  try {
    final result = Process.runSync(
      'git',
      ['config', '--get', 'remote.origin.url'],
      workingDirectory: workspacePath,
    );
    if (result.exitCode != 0) return null;

    var url = result.stdout.toString().trim();
    if (url.isEmpty) return null;

    // SSH 格式: git@host:user/repo.git
    final sshMatch = RegExp(r'git@(.+?):(.+?)(?:\.git)?$').firstMatch(url);
    if (sshMatch != null) {
      return 'https://${sshMatch.group(1)}/${sshMatch.group(2)}';
    }

    // HTTPS 格式: https://host/user/repo.git
    final httpsMatch =
        RegExp(r'(https?://.+?)(?:\.git)?$').firstMatch(url);
    if (httpsMatch != null) {
      return httpsMatch.group(1);
    }

    // git:// 格式: git://host/user/repo.git
    final gitMatch =
        RegExp(r'git://(.+?)(?:\.git)?$').firstMatch(url);
    if (gitMatch != null) {
      return 'https://${gitMatch.group(1)}';
    }

    return null;
  } catch (_) {
    return null;
  }
}

/// 获取当前 git 分支名称。
String _getGitBranch(String workspacePath) {
  try {
    final result = Process.runSync(
      'git',
      ['rev-parse', '--abbrev-ref', 'HEAD'],
      workingDirectory: workspacePath,
    );
    if (result.exitCode == 0) {
      final branch = result.stdout.toString().trim();
      if (branch.isNotEmpty && branch != 'HEAD') return branch;
    }
  } catch (_) {}
  return 'main';
}

/// 构建模块的 repository URL。
/// 格式: https://github.com/user/repo/tree/branch/module/relative/path
String? _buildModuleRepositoryUrl(
    String workspacePath, String modulePath) {
  final repoUrl = _getGitHubRepoUrl(workspacePath);
  if (repoUrl == null) return null;

  final branch = _getGitBranch(workspacePath);
  var relativePath = modulePath.startsWith(workspacePath)
      ? modulePath.substring(workspacePath.length + 1)
      : modulePath;
  relativePath = relativePath.replaceAll('\\', '/');

  return '$repoUrl/tree/$branch/$relativePath';
}

/// 向模块的 pubspec.yaml 添加 repository 字段。
void _addRepositoryField(String workspacePath, String modulePath) {
  final repoUrl = _buildModuleRepositoryUrl(workspacePath, modulePath);
  if (repoUrl == null) {
    logger.d('无法获取 git 仓库地址，跳过 repository 字段');
    return;
  }

  final pubspecFile = File('$modulePath/pubspec.yaml');
  if (!pubspecFile.existsSync()) return;

  final content = pubspecFile.readAsStringSync();

  // 已有 repository 字段则跳过
  if (RegExp(r'^repository:', multiLine: true).hasMatch(content)) {
    logger.d('模块已包含 repository 字段，跳过');
    return;
  }

  // 移除注释掉的 repository 行
  var cleaned =
      content.replaceAll(RegExp(r'# *repository:.*\n'), '');

  // 在 description 或 version 后插入 repository
  final insertPattern =
      RegExp(r'((?:version|description):.*\n)');
  final match = insertPattern.firstMatch(cleaned);
  if (match != null) {
    final insertPos = match.end;
    cleaned = '${cleaned.substring(0, insertPos)}repository: $repoUrl\n${cleaned.substring(insertPos)}';
    pubspecFile.writeAsStringSync(cleaned);
    logger.i('已添加 repository: $repoUrl');
  }
}

/// 向模块的 pubspec.yaml 添加 `resolution: workspace`。
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

/// 更新根目录 pubspec.yaml 的 workspace 列表，可选添加新模块。
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

/// 在工作区中注册模块（同时更新模块和根目录的 pubspec）。
void registerModule(Directory workspaceRoot, Directory modulePath) {
  updateModulePubspec(modulePath.path);
  _addRepositoryField(workspaceRoot.path, modulePath.path);
  updateRootPubspec(workspaceRoot.path, modulePath.path);
}
