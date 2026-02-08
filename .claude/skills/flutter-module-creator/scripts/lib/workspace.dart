import 'dart:io';

import 'package:path/path.dart' as path;

/// Get workspace root from a script path.
/// Scripts are at `<workspace>/.claude/skills/<skill>/scripts/`.
Directory getWorkspaceRoot(String scriptPath) {
  final scriptDir = path.dirname(scriptPath);
  return Directory(
      path.normalize(path.join(scriptDir, '..', '..', '..', '..')));
}

/// Read .env file from workspace root, returns key-value map.
Map<String, String> readEnv(Directory workspaceRoot) {
  final envFile = File(path.join(workspaceRoot.path, '.env'));
  final env = <String, String>{};
  if (!envFile.existsSync()) return env;
  for (var line in envFile.readAsLinesSync()) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final index = line.indexOf('=');
    if (index == -1) continue;
    env[line.substring(0, index).trim()] = line.substring(index + 1).trim();
  }
  return env;
}

/// Get organization from .env config.
String getOrganization(Directory workspaceRoot) {
  return readEnv(workspaceRoot)['ORG'] ?? 'com.example';
}
