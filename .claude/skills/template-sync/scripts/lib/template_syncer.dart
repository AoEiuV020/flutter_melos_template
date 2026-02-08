import 'dart:io';

import 'package:project_workspace/project_workspace.dart';

import 'git_helpers.dart';

/// Sync template updates into an existing project.
///
/// If previously synced (remote + graft exist), just fetch and merge.
/// Otherwise, detect initial commit, establish graft, then merge.
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

/// Update an existing sync: fetch + merge.
Future<void> _updateSync(String projectPath, {bool dryRun = false}) async {
  logger.i('Previous sync detected, updating...');

  if (dryRun) {
    logger.i('[DRY RUN] Would fetch and merge template/main');
    return;
  }

  await _fetchTemplate(projectPath);
  await _mergeTemplate(projectPath);
}

/// First-time sync: detect commit, add remote, graft, fetch, merge.
Future<void> _firstSync({
  required String projectPath,
  required String templatePath,
  String? templateCommitSha,
  bool dryRun = false,
}) async {
  final isLocalPath = Directory(templatePath).existsSync();

  // Step 1: Detect initial commit
  final initialCommit = await getInitialCommit(projectPath);
  if (initialCommit == null || initialCommit.isEmpty) {
    logger.e('Cannot detect initial commit.');
    exit(1);
  }
  logger.i('Project initial commit: $initialCommit');

  // Step 2: Determine template commit
  final templateCommit = await _resolveTemplateCommit(
    projectPath: projectPath,
    templatePath: templatePath,
    initialCommit: initialCommit,
    userProvided: templateCommitSha,
    isLocalPath: isLocalPath,
  );
  logger.i('Template commit: $templateCommit');

  if (dryRun) {
    logger.i('[DRY RUN] Would graft: $initialCommit -> $templateCommit');
    logger.i('[DRY RUN] Would merge template/main');
    return;
  }

  // Step 3: Add remote + fetch
  if (!await remoteExists(projectPath, 'template')) {
    logger.i('Adding template remote: $templatePath');
    await runCommand(
      ['git', 'remote', 'add', 'template', templatePath],
      workingDirectory: projectPath,
    );
  }
  await _fetchTemplate(projectPath);

  // Step 4: Establish graft
  if (!await graftExists(projectPath, initialCommit)) {
    logger.i('Establishing graft: $initialCommit -> $templateCommit');
    final ok = await runCommand(
      ['git', 'replace', '--graft', initialCommit, templateCommit],
      workingDirectory: projectPath,
    );
    if (!ok) exit(1);
  }

  // Step 5: Merge
  await _mergeTemplate(projectPath);
}

/// Resolve which template commit to use as graft parent.
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
    logger.e('Cannot get timestamp of initial commit.');
    exit(1);
  }
  logger.i('Initial commit time: $initialTime');

  if (isLocalPath) {
    final commit = await findTemplateCommitByTime(templatePath, initialTime);
    if (commit == null) {
      logger.e('No template commit found before initial time.');
      exit(1);
    }
    return commit;
  }

  // Remote URL: add remote + fetch first, then search fetched refs
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
    logger.e('No template commit found before initial time. '
        'Please provide --template-commit');
    exit(1);
  }
  return commit;
}

/// Fetch from template remote.
Future<void> _fetchTemplate(String repoPath) async {
  logger.i('Fetching template...');
  final ok = await runCommand(
    ['git', 'fetch', 'template'],
    workingDirectory: repoPath,
  );
  if (!ok) exit(1);
}

/// Merge template/main into current branch.
Future<void> _mergeTemplate(String repoPath) async {
  logger.i('Merging template/main...');

  final output = await runCommandOutput(
    ['git', 'merge', 'template/main', '--no-edit'],
    workingDirectory: repoPath,
  );

  if (output == null) {
    // Check if it's a conflict
    final conflicts = await runCommandOutput(
      ['git', 'diff', '--name-only', '--diff-filter=U'],
      workingDirectory: repoPath,
    );
    if (conflicts != null && conflicts.isNotEmpty) {
      logger.w('Merge has conflicts:');
      for (final f in conflicts.split('\n')) {
        logger.w('  CONFLICT: $f');
      }
      logger.i(
          'Resolve conflicts, then: git add <files> && git commit --no-edit');
    }
    exit(1);
  }

  if (output.contains('Already up to date')) {
    logger.i('Already up to date.');
  } else {
    logger.i('✅ Template sync completed successfully!');
  }
}
