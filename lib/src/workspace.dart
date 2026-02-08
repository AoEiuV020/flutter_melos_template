import 'dart:io';

import 'package:path/path.dart' as path;

/// Get workspace root directory from a script path.
/// Scripts are at `<workspace>/.claude/skills/<skill>/scripts/`.
Directory getWorkspaceRoot(String scriptPath) {
  final scriptDir = path.dirname(scriptPath);
  return Directory(
      path.normalize(path.join(scriptDir, '..', '..', '..', '..')));
}
