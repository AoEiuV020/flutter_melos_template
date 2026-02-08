#!/usr/bin/env dart
/// Template Sync — merge upstream template updates into derived projects.
///
/// Usage: dart run sync_template.dart [--template <path>] [options]

import 'dart:io';

import 'package:args/args.dart';
import 'package:project_workspace/project_workspace.dart';

import 'lib/template_syncer.dart';

void main(List<String> arguments) async {
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

  final scriptPath = Platform.script.toFilePath();
  final workspaceRoot = getWorkspaceRoot(scriptPath);
  final projectPath = workspaceRoot.path;

  // Resolve template path: --template arg > .env TEMPLATE_REPO
  String? templateArg = args['template'] as String?;
  if (templateArg == null) {
    final config = ProjectConfig(workspaceRoot);
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
      : templateArg;

  await syncTemplate(
    projectPath: projectPath,
    templatePath: templatePath,
    templateCommitSha: args['template-commit'] as String?,
    dryRun: args['dry-run'] as bool,
  );
}
