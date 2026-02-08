import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../update-workspace/scripts/lib/workspace_updater.dart';

/// Update analysis_options.yaml by copying from workspace root and adjusting the include line.
void updateAnalysisOptions(
  Directory modulePath,
  Directory workspaceRoot, {
  bool useFlutter = true,
}) {
  final rootAnalysis =
      File(path.join(workspaceRoot.path, 'analysis_options.yaml'));
  if (!rootAnalysis.existsSync()) {
    print('Warning: No analysis_options.yaml found in workspace root');
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

/// Copy LICENSE file from workspace root if exists.
void copyLicense(Directory workspaceRoot, Directory modulePath) {
  final licenseFile = File(path.join(workspaceRoot.path, 'LICENSE'));
  if (licenseFile.existsSync()) {
    final destFile = File(path.join(modulePath.path, 'LICENSE'));
    destFile.writeAsStringSync(licenseFile.readAsStringSync());
  }
}

/// Remove platform directories that might interfere with creation.
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

/// Ensure a directory exists, creating it if necessary.
Directory ensureDir(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

/// Common post-creation setup: copy license, update analysis, update workspace.
void finalizeModule(
  Directory workspaceRoot,
  Directory modulePath, {
  bool useFlutter = true,
  bool withLicense = true,
}) {
  if (withLicense) {
    copyLicense(workspaceRoot, modulePath);
  }
  updateAnalysisOptions(modulePath, workspaceRoot, useFlutter: useFlutter);
  updateModulePubspec(modulePath.path);
  updateRootPubspec(workspaceRoot.path, modulePath.path);
}
