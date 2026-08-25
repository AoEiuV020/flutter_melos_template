import 'package:project_workspace/project_workspace.dart';

/// 获取初始（第一个）commit，绕过 graft 替换。
Future<String?> getInitialCommit(String repoPath) async {
  final output = await runCommandOutput(
    ['git', '--no-replace-objects', 'rev-list', '--max-parents=0', 'HEAD'],
    workingDirectory: repoPath,
  );
  if (output == null || output.isEmpty) return null;
  final commits = output.split('\n');
  return commits.last.trim();
}

/// 获取 commit 的时间戳（unix 纪元）。
Future<int?> getCommitTime(String repoPath, String sha) async {
  final output = await runCommandOutput(
    ['git', 'log', '-1', '--format=%ct', sha],
    workingDirectory: repoPath,
  );
  if (output == null) return null;
  return int.tryParse(output.trim());
}

/// 检查 git remote 是否存在。
Future<bool> remoteExists(String repoPath, String remoteName) async {
  final output = await runCommandOutput(
    ['git', 'remote'],
    workingDirectory: repoPath,
  );
  if (output == null) return false;
  return output.split('\n').any((line) => line.trim() == remoteName);
}

/// 检查是否存在任何 graft/replace 引用。
Future<bool> hasAnyGraft(String repoPath) async {
  final output = await runCommandOutput(
    ['git', 'replace', '--list'],
    workingDirectory: repoPath,
  );
  return output != null && output.isNotEmpty;
}

/// 检查特定 commit 的 graft/replace 引用是否存在。
Future<bool> graftExists(String repoPath, String sha) async {
  final output = await runCommandOutput(
    ['git', 'replace', '--list'],
    workingDirectory: repoPath,
  );
  if (output == null) return false;
  final prefix = sha.substring(0, 7);
  return output.split('\n').any((line) => line.startsWith(prefix));
}

/// 查找最接近 [beforeTime] 但不晚于该时间的模板 commit。
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
