import 'dart:io';

import 'package:path/path.dart' as path;

/// Get workspace root from a script path.
/// Scripts are at `<workspace>/.claude/skills/<skill>/scripts/`.
Directory getWorkspaceRoot(String scriptPath) {
  final scriptDir = path.dirname(scriptPath);
  return Directory(
      path.normalize(path.join(scriptDir, '..', '..', '..', '..')));
}

/// Extract organization from existing modules or use default.
String getOrganization(Directory workspaceRoot) {
  for (final subdir in ['apps', 'packages']) {
    final dirPath = Directory(path.join(workspaceRoot.path, subdir));
    if (dirPath.existsSync()) {
      for (final module in dirPath.listSync().whereType<Directory>()) {
        final androidManifest = File(path.join(
          module.path,
          'android',
          'app',
          'src',
          'main',
          'AndroidManifest.xml',
        ));
        if (androidManifest.existsSync()) {
          final content = androidManifest.readAsStringSync();
          final match = RegExp(r'package="([^"]+)"').firstMatch(content);
          if (match != null) {
            final parts = match.group(1)!.split('.');
            if (parts.length > 1) {
              parts.removeLast();
              return parts.join('.');
            }
          }
        }
      }
    }
  }
  return 'com.example';
}
