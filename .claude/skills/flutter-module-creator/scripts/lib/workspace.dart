import 'dart:io';

import 'package:path/path.dart' as path;

/// Find the workspace root by looking for pubspec.yaml with melos config.
Directory findWorkspaceRoot() {
  var current = Directory.current;
  while (true) {
    final pubspec = File(path.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (content.contains('melos:') || content.contains('workspace:')) {
        return current;
      }
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current;
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
