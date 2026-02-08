import 'package:project_workspace/project_workspace.dart';

/// Get the initial (first) commit, bypassing graft replacements.
Future<String?> getInitialCommit(String repoPath) async {
  final output = await runCommandOutput(
    ['git', '--no-replace-objects', 'rev-list', '--max-parents=0', 'HEAD'],
    workingDirectory: repoPath,
  );
  if (output == null || output.isEmpty) return null;
  final commits = output.split('\n');
  return commits.last.trim();
}

/// Get the commit timestamp (unix epoch).
Future<int?> getCommitTime(String repoPath, String sha) async {
  final output = await runCommandOutput(
    ['git', 'log', '-1', '--format=%ct', sha],
    workingDirectory: repoPath,
  );
  if (output == null) return null;
  return int.tryParse(output.trim());
}

/// Check if a git remote exists.
Future<bool> remoteExists(String repoPath, String remoteName) async {
  final output = await runCommandOutput(
    ['git', 'remote'],
    workingDirectory: repoPath,
  );
  if (output == null) return false;
  return output.split('\n').any((line) => line.trim() == remoteName);
}

/// Check if any graft/replace refs exist.
Future<bool> hasAnyGraft(String repoPath) async {
  final output = await runCommandOutput(
    ['git', 'replace', '--list'],
    workingDirectory: repoPath,
  );
  return output != null && output.isNotEmpty;
}

/// Check if a graft/replace ref exists for a specific commit.
Future<bool> graftExists(String repoPath, String sha) async {
  final output = await runCommandOutput(
    ['git', 'replace', '--list'],
    workingDirectory: repoPath,
  );
  if (output == null) return false;
  final prefix = sha.substring(0, 7);
  return output.split('\n').any((line) => line.startsWith(prefix));
}

/// Find the template commit closest to (but not after) [beforeTime].
Future<String?> findTemplateCommitByTime(
  String repoPath,
  int beforeTime, {
  String ref = 'HEAD',
}) async {
  final output = await runCommandOutput(
    ['git', 'log', '--format=%H %ct', '--reverse', ref],
    workingDirectory: repoPath,
  );
  if (output == null) return null;

  String? best;
  for (final line in output.split('\n')) {
    final parts = line.split(' ');
    if (parts.length < 2) continue;
    final time = int.tryParse(parts[1]);
    if (time == null) continue;
    if (time <= beforeTime) {
      best = parts[0];
    } else {
      break;
    }
  }
  return best;
}
