import 'dart:io';

import 'package:project_workspace/project_workspace.dart';

import 'git_helpers.dart';

/// 将模板更新同步到现有项目中。
///
/// 如果之前已同步过（remote + graft 已存在），仅执行 fetch 和 merge。
/// 否则，检测初始 commit，建立 graft，然后 merge。
Future<void> syncTemplate({
  required String projectPath,
  required String templatePath,
  String? templateCommitSha,
  bool dryRun = false,
}) async {
  final hasRemote = await remoteExists(projectPath, 'template');
  final hasGraft = await hasAnyGraft(projectPath);

  if (hasRemote && hasGraft) {
    await _updateSync(projectPath, dryRun: dryRun);
    return;
  }

  await _firstSync(
    projectPath: projectPath,
    templatePath: templatePath,
    templateCommitSha: templateCommitSha,
    dryRun: dryRun,
  );
}

/// 更新已有的同步: fetch + merge。
Future<void> _updateSync(String projectPath, {bool dryRun = false}) async {
  logger.i('检测到之前的同步记录，正在更新...');

  if (dryRun) {
    logger.i('[演练模式] 将执行 fetch 和 merge template/main');
    return;
  }

  await _fetchTemplate(projectPath);
  await _mergeTemplate(projectPath);
}

/// 首次同步: 检测 commit，添加 remote，建立 graft，fetch，merge。
Future<void> _firstSync({
  required String projectPath,
  required String templatePath,
  String? templateCommitSha,
  bool dryRun = false,
}) async {
  final isLocalPath = Directory(templatePath).existsSync();

  // 步骤 1: 检测初始 commit
  final initialCommit = await getInitialCommit(projectPath);
  if (initialCommit == null || initialCommit.isEmpty) {
    logger.e('无法检测初始 commit。');
    exit(1);
  }
  logger.i('项目初始 commit: $initialCommit');

  // 步骤 2: 确定模板 commit
  final templateCommit = await _resolveTemplateCommit(
    projectPath: projectPath,
    templatePath: templatePath,
    initialCommit: initialCommit,
    userProvided: templateCommitSha,
    isLocalPath: isLocalPath,
  );
  logger.i('模板 commit: $templateCommit');

  if (dryRun) {
    logger.i('[演练模式] 将建立 graft: $initialCommit -> $templateCommit');
    logger.i('[演练模式] 将执行 merge template/main');
    return;
  }

  // 步骤 3: 添加 remote + fetch
  if (!await remoteExists(projectPath, 'template')) {
    logger.i('添加模板 remote: $templatePath');
    await runCommand(
      ['git', 'remote', 'add', 'template', templatePath],
      workingDirectory: projectPath,
    );
  }
  await _fetchTemplate(projectPath);

  // 步骤 4: 建立 graft
  if (!await graftExists(projectPath, initialCommit)) {
    logger.i('建立 graft: $initialCommit -> $templateCommit');
    final ok = await runCommand(
      ['git', 'replace', '--graft', initialCommit, templateCommit],
      workingDirectory: projectPath,
    );
    if (!ok) exit(1);
  }

  // 步骤 5: Merge
  await _mergeTemplate(projectPath);
}

/// 解析用作 graft 父节点的模板 commit。
Future<String> _resolveTemplateCommit({
  required String projectPath,
  required String templatePath,
  required String initialCommit,
  required bool isLocalPath,
  String? userProvided,
}) async {
  if (userProvided != null) return userProvided;

  final initialTime = await getCommitTime(projectPath, initialCommit);
  if (initialTime == null) {
    logger.e('无法获取初始 commit 的时间戳。');
    exit(1);
  }
  logger.i('初始 commit 时间: $initialTime');

  if (isLocalPath) {
    final commit = await findTemplateCommitByTime(templatePath, initialTime);
    if (commit == null) {
      logger.e('未找到初始时间之前的模板 commit。');
      exit(1);
    }
    return commit;
  }

  // 远程 URL: 先添加 remote + fetch，然后搜索已拉取的引用
  if (!await remoteExists(projectPath, 'template')) {
    await runCommand(
      ['git', 'remote', 'add', 'template', templatePath],
      workingDirectory: projectPath,
    );
  }
  await _fetchTemplate(projectPath);

  final commit = await findTemplateCommitByTime(
    projectPath,
    initialTime,
    ref: 'template/main',
  );
  if (commit == null) {
    logger.e('未找到初始时间之前的模板 commit。'
        '请提供 --template-commit');
    exit(1);
  }
  return commit;
}

/// 从模板 remote 拉取。
Future<void> _fetchTemplate(String repoPath) async {
  logger.i('正在拉取模板...');
  final ok = await runCommand(
    ['git', 'fetch', 'template'],
    workingDirectory: repoPath,
  );
  if (!ok) exit(1);
}

/// 将 template/main 合并到当前分支。
Future<void> _mergeTemplate(String repoPath) async {
  logger.i('正在合并 template/main...');

  final output = await runCommandOutput(
    ['git', 'merge', 'template/main', '--no-edit'],
    workingDirectory: repoPath,
  );

  if (output == null) {
    // 检查是否存在冲突
    final conflicts = await runCommandOutput(
      ['git', 'diff', '--name-only', '--diff-filter=U'],
      workingDirectory: repoPath,
    );
    if (conflicts != null && conflicts.isNotEmpty) {
      logger.w('合并存在冲突:');
      for (final f in conflicts.split('\n')) {
        logger.w('  冲突: $f');
      }
      logger.i(
          '请解决冲突后执行: git add <文件> && git commit --no-edit');
    }
    exit(1);
  }

  if (output.contains('Already up to date')) {
    logger.i('已是最新状态。');
  } else {
    logger.i('✅ 模板同步成功完成！');
  }
}
