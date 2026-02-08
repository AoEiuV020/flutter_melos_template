import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;

/// Get workspace root from a script path.
/// Scripts are at `<workspace>/.claude/skills/<skill>/scripts/`.
Directory getWorkspaceRoot(String scriptPath) {
  final scriptDir = path.dirname(scriptPath);
  return Directory(
    path.normalize(path.join(scriptDir, '..', '..', '..', '..')),
  );
}

/// Read .env file from workspace root.
DotEnv readEnv(Directory workspaceRoot) {
  final envPath = path.join(workspaceRoot.path, '.env');
  final env = DotEnv();
  if (File(envPath).existsSync()) {
    env.load([envPath]);
  }
  return env;
}

/// Get organization from .env config.
String getOrganization(Directory workspaceRoot) {
  return readEnv(workspaceRoot)['ORG'] ?? 'com.example';
}
