#!/usr/bin/env dart

/// Sync template changes into a project derived from flutter_melos_template.

import 'dart:io';

import 'package:args/args.dart';
import 'package:project_workspace/project_workspace.dart';

/// Get the initial (first) commit of the current repo.
String _getInitialCommit(String repoPath) {
  final result = Process.runSync(
    'git',
    ['rev-list', '--max-parents=0', 'HEAD'],
    workingDirectory: repoPath,
  );
  if (result.exitCode != 0) {
    logger.e('Failed to get initial commit: ${result.stderr}');
    exit(1);
  }
  final commits = (result.stdout as String).trim().split('\n');
  // Return the oldest (last in reverse chronological order)
  return commits.last.trim();
}

/// Get the commit timestamp (unix epoch) of a commit.
int _getCommitTime(String repoPath, String sha) {
  final result = Process.runSync(
    'git',
    ['log', '-1', '--format=%ct', sha],
    workingDirectory: repoPath,
  );
  if (result.exitCode != 0) {
    logger.e('Failed to get commit time for $sha: ${result.stderr}');
    exit(1);
  }
  return int.parse((result.stdout as String).trim());
}

/// Find the template commit just before the given timestamp.
String _findTemplateCommitByTime(String templatePath, int beforeTime) {
  final result = Process.runSync(
    'git',
    ['log', '--format=%H %ct', '--reverse', 'HEAD'],
    workingDirectory: templatePath,
  );
  if (result.exitCode != 0) {
    logger.e('Failed to list template commits: ${result.stderr}');
    exit(1);
  }

  String? best;
  for (final line in (result.stdout as String).trim().split('\n')) {
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

  if (best == null) {
    logger.e('No template commit found before timestamp $beforeTime');
    exit(1);
  }
  return best;
}

/// Check if a git remote exists.
bool _remoteExists(String repoPath, String remoteName) {
  final result = Process.runSync(
    'git',
    ['remote'],
    workingDirectory: repoPath,
  );
  return (result.stdout as String)
      .split('\n')
      .any((line) => line.trim() == remoteName);
}

/// Get the URL of an existing remote.
String _getRemoteUrl(String repoPath, String remoteName) {
  final result = Process.runSync(
    'git',
    ['remote', 'get-url', remoteName],
    workingDirectory: repoPath,
  );
  return (result.stdout as String).trim();
}

/// Check if a graft/replace ref exists for a commit.
bool _graftExists(String repoPath, String sha) {
  final result = Process.runSync(
    'git',
    ['replace', '--list'],
    workingDirectory: repoPath,
  );
  return (result.stdout as String).split('\n').any((line) => line.startsWith(sha.substring(0, 7)));
}

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('template',
        abbr: 't', help: 'Path to the template repository (required)')
    ..addOption('template-commit',
        abbr: 'c', help: 'Template commit SHA the project was based on')
    ..addFlag('dry-run',
        help: 'Show what would be done without executing', negatable: false)
    ..addFlag('help',
        abbr: 'h', help: 'Show usage information', negatable: false);

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    print(parser.usage);
    exit(1);
  }

  if (args['help'] as bool) {
    print('Sync template changes into the current project.\n');
    print('Usage: dart run sync_template.dart [--template <path>] [options]\n');
    print(parser.usage);
    exit(0);
  }

  final projectPath = Directory.current.path;

  // Resolve template path: --template arg > .env TEMPLATE_REPO
  String? templateArg = args['template'] as String?;
  if (templateArg == null) {
    final config = ProjectConfig(Directory(projectPath));
    templateArg = config.templateRepo;
    if (templateArg == null) {
      print('Error: --template is required (or set TEMPLATE_REPO in .env)\n');
      print(parser.usage);
      exit(1);
    }
    logger.i('Template from .env: $templateArg');
  }

  final templatePath = Directory(templateArg).existsSync()
      ? Directory(templateArg).absolute.path
      : templateArg; // URL or path
  final dryRun = args['dry-run'] as bool;
  final isLocalPath = Directory(templatePath).existsSync();

  // Step 1: Get initial commit of the project
  final initialCommit = _getInitialCommit(projectPath);
  logger.i('Project initial commit: $initialCommit');

  // Step 2: Determine template commit
  String templateCommit;
  if (args['template-commit'] != null) {
    templateCommit = args['template-commit'] as String;
    logger.i('Template commit (user provided): $templateCommit');
  } else if (isLocalPath) {
    final initialTime = _getCommitTime(projectPath, initialCommit);
    logger.i('Initial commit time: $initialTime');
    templateCommit = _findTemplateCommitByTime(templatePath, initialTime);
    logger.i('Template commit (auto-detected by time): $templateCommit');
  } else {
    // Remote URL: need to fetch first, then detect by time
    logger.i('Template is remote URL, fetching first...');

    // Add remote early to fetch
    if (!_remoteExists(projectPath, 'template')) {
      Process.runSync('git', ['remote', 'add', 'template', templatePath],
          workingDirectory: projectPath);
    }
    final fetchResult = Process.runSync('git', ['fetch', 'template'],
        workingDirectory: projectPath);
    if (fetchResult.exitCode != 0) {
      logger.e('Failed to fetch template: ${fetchResult.stderr}');
      exit(1);
    }

    // Use fetched refs to find commit by time
    final initialTime = _getCommitTime(projectPath, initialCommit);
    logger.i('Initial commit time: $initialTime');

    // List template commits from fetched refs
    final logResult = Process.runSync(
      'git',
      ['log', '--format=%H %ct', '--reverse', 'template/main'],
      workingDirectory: projectPath,
    );
    if (logResult.exitCode != 0) {
      logger.e('Failed to list template commits');
      exit(1);
    }

    String? best;
    for (final line in (logResult.stdout as String).trim().split('\n')) {
      final parts = line.split(' ');
      if (parts.length < 2) continue;
      final time = int.tryParse(parts[1]);
      if (time == null) continue;
      if (time <= initialTime) {
        best = parts[0];
      } else {
        break;
      }
    }
    if (best == null) {
      logger.e('No template commit found before initial commit time. Please provide --template-commit');
      exit(1);
    }
    templateCommit = best;
    logger.i('Template commit (auto-detected by time from remote): $templateCommit');
  }

  // Verify template commit exists (in local repo if fetched, or template path)
  final verifyDir = isLocalPath ? templatePath : projectPath;
  final verifyResult = Process.runSync(
    'git',
    ['cat-file', '-t', templateCommit],
    workingDirectory: verifyDir,
  );
  if (verifyResult.exitCode != 0) {
    logger.e('Template commit not found: $templateCommit');
    exit(1);
  }

  if (dryRun) {
    logger.i('[DRY RUN] Would add template remote: $templatePath');
    logger.i('[DRY RUN] Would graft: $initialCommit -> $templateCommit');
    logger.i('[DRY RUN] Would merge template/main');
    exit(0);
  }

  // Step 3: Add template remote
  if (!_remoteExists(projectPath, 'template')) {
    logger.i('Adding template remote: $templatePath');
    final result = Process.runSync(
      'git',
      ['remote', 'add', 'template', templatePath],
      workingDirectory: projectPath,
    );
    if (result.exitCode != 0) {
      logger.e('Failed to add remote: ${result.stderr}');
      exit(1);
    }
  } else {
    final existingUrl = _getRemoteUrl(projectPath, 'template');
    logger.i('Template remote already exists: $existingUrl');
  }

  // Step 4: Fetch template
  logger.i('Fetching template...');
  final fetchResult = Process.runSync(
    'git',
    ['fetch', 'template'],
    workingDirectory: projectPath,
  );
  if (fetchResult.exitCode != 0) {
    logger.e('Failed to fetch template: ${fetchResult.stderr}');
    exit(1);
  }

  // Step 5: Establish graft (if not already)
  if (!_graftExists(projectPath, initialCommit)) {
    logger.i('Establishing graft: $initialCommit -> $templateCommit');
    final graftResult = Process.runSync(
      'git',
      ['replace', '--graft', initialCommit, templateCommit],
      workingDirectory: projectPath,
    );
    if (graftResult.exitCode != 0) {
      logger.e('Failed to create graft: ${graftResult.stderr}');
      exit(1);
    }
  } else {
    logger.i('Graft already exists for $initialCommit');
  }

  // Step 6: Verify merge-base
  final mergeBaseResult = Process.runSync(
    'git',
    ['merge-base', 'main', 'template/main'],
    workingDirectory: projectPath,
  );
  if (mergeBaseResult.exitCode != 0) {
    logger.e('Failed to find merge-base: ${mergeBaseResult.stderr}');
    exit(1);
  }
  logger.i('Merge base: ${(mergeBaseResult.stdout as String).trim()}');

  // Step 7: Merge
  logger.i('Merging template/main...');
  final mergeResult = Process.runSync(
    'git',
    ['merge', 'template/main', '--no-edit'],
    workingDirectory: projectPath,
  );

  if (mergeResult.exitCode != 0) {
    final stderr = (mergeResult.stderr as String);
    if (stderr.contains('CONFLICT')) {
      logger.w('Merge has conflicts. Please resolve manually:');
      // List conflicting files
      final conflictsResult = Process.runSync(
        'git',
        ['diff', '--name-only', '--diff-filter=U'],
        workingDirectory: projectPath,
      );
      final conflicts = (conflictsResult.stdout as String).trim();
      if (conflicts.isNotEmpty) {
        for (final f in conflicts.split('\n')) {
          logger.w('  CONFLICT: $f');
        }
      }
      logger.i('After resolving: git add <files> && git commit --no-edit');
      exit(1);
    }
    logger.e('Merge failed: $stderr');
    exit(1);
  }

  logger.i('✅ Template sync completed successfully!');
}
