import 'dart:io';

import 'package:path/path.dart' as path;

import 'log.dart';
import 'pubspec_updater.dart';

/// 更新 analysis_options.yaml，从工作区根目录复制并调整 include 行。
void setupAnalysisOptions(
  Directory workspaceRoot,
  Directory modulePath, {
  bool useFlutter = true,
}) {
  final rootAnalysis =
      File(path.join(workspaceRoot.path, 'analysis_options.yaml'));
  if (!rootAnalysis.existsSync()) {
    logger.w('工作区根目录未找到 analysis_options.yaml');
    return;
  }

  final lines = rootAnalysis.readAsLinesSync();
  if (lines.isNotEmpty && lines.first.startsWith('include:')) {
    lines[0] = useFlutter
        ? 'include: package:flutter_lints/flutter.yaml'
        : 'include: package:lints/recommended.yaml';
  }

  final analysisFile =
      File(path.join(modulePath.path, 'analysis_options.yaml'));
  analysisFile.writeAsStringSync('${lines.join('\n')}\n');
}

/// 从工作区根目录复制 LICENSE 文件（如果存在）。
void copyLicense(Directory workspaceRoot, Directory modulePath) {
  final licenseFile = File(path.join(workspaceRoot.path, 'LICENSE'));
  if (licenseFile.existsSync()) {
    final destFile = File(path.join(modulePath.path, 'LICENSE'));
    destFile.writeAsStringSync(licenseFile.readAsStringSync());
  }
}

/// 删除可能干扰创建的平台目录。
void removePlatformDirs(Directory dir) {
  for (final platform in [
    'windows',
    'macos',
    'linux',
    'ios',
    'android',
    'web'
  ]) {
    final platformDir = Directory(path.join(dir.path, platform));
    if (platformDir.existsSync()) {
      platformDir.deleteSync(recursive: true);
    }
  }
}

/// 确保目录存在，必要时创建。
Directory ensureDir(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

/// 通用的创建后设置: 复制许可证、更新分析选项、注册到工作区。
void finalizeModule(
  Directory workspaceRoot,
  Directory modulePath, {
  bool useFlutter = true,
  bool withLicense = true,
}) {
  if (withLicense) {
    copyLicense(workspaceRoot, modulePath);
  }
  setupAnalysisOptions(workspaceRoot, modulePath, useFlutter: useFlutter);
  registerModule(workspaceRoot, modulePath);
}
