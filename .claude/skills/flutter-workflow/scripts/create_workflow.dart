#!/usr/bin/env dart
/// Create GitHub Actions workflow for Flutter app in Melos workspace.
///
/// Usage:
///     dart run create_workflow.dart <app_path> [--name <workflow_name>]
///
/// Examples:
///     dart run create_workflow.dart apps/my_app
///     dart run create_workflow.dart apps/my_app --name ci.yml

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// Get workspace root from a script path.
/// Scripts are at `<workspace>/.claude/skills/<skill>/scripts/`.
Directory getWorkspaceRoot(String scriptPath) {
  final scriptDir = path.dirname(scriptPath);
  return Directory(
      path.normalize(path.join(scriptDir, '..', '..', '..', '..')));
}

/// Create workflow file from template.
File createWorkflow(
  String appPath, {
  String workflowName = 'main',
  required Directory workspaceRoot,
  required Directory scriptDir,
}) {
  // Normalize app path
  appPath = appPath.replaceAll(RegExp(r'/+$'), '');
  if (!appPath.startsWith('apps/') && !appPath.startsWith('packages/')) {
    // Assume it's under apps/
    if (!appPath.contains('/')) {
      appPath = 'apps/$appPath';
    }
  }

  // Check if app exists
  final fullAppPath = Directory(path.join(workspaceRoot.path, appPath));
  if (!fullAppPath.existsSync()) {
    print('Error: App path does not exist: ${fullAppPath.path}');
    exit(1);
  }

  // Locate template
  final templatePath = File(
    path.join(scriptDir.parent.path, 'assets', 'main.yml.template'),
  );

  if (!templatePath.existsSync()) {
    print('Error: Template not found: ${templatePath.path}');
    exit(1);
  }

  // Read template
  var content = templatePath.readAsStringSync();

  // Replace placeholder with app path
  content = content.replaceAll('apps/__APP_NAME__', appPath);

  // Create .github/workflows directory
  final workflowsDir = Directory(
    path.join(workspaceRoot.path, '.github', 'workflows'),
  );
  if (!workflowsDir.existsSync()) {
    workflowsDir.createSync(recursive: true);
  }

  // Ensure workflow name has .yml extension
  if (!workflowName.endsWith('.yml') && !workflowName.endsWith('.yaml')) {
    workflowName = '$workflowName.yml';
  }

  // Write workflow file
  final outputPath = File(path.join(workflowsDir.path, workflowName));
  outputPath.writeAsStringSync(content);

  print('✅ Created workflow: ${outputPath.path}');
  print('   App path: $appPath');
  return outputPath;
}

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Workflow filename (default: main)',
      defaultsTo: 'main',
    )
    ..addOption(
      'workspace',
      abbr: 'w',
      help: 'Workspace root path (auto-detected if not specified)',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information',
      negatable: false,
    );

  ArgResults args;
  List<String> rest;
  try {
    args = parser.parse(arguments);
    rest = args.rest;
  } catch (e) {
    print('Error: $e\n');
    print('Usage: dart run create_workflow.dart <app_path> [options]');
    print('');
    print(parser.usage);
    exit(1);
  }

  if (args['help'] as bool || rest.isEmpty) {
    print('Create GitHub Actions workflow for Flutter app');
    print('');
    print('Usage: dart run create_workflow.dart <app_path> [options]');
    print('');
    print('Examples:');
    print('  dart run create_workflow.dart apps/my_app');
    print('  dart run create_workflow.dart apps/my_app --name ci');
    print('');
    print('Options:');
    print(parser.usage);
    exit(rest.isEmpty ? 1 : 0);
  }

  final appPath = rest.first;
  final workflowName = args['name'] as String;
  final scriptPath = Platform.script.toFilePath();
  final scriptDir = Directory(path.dirname(scriptPath));
  final workspaceRoot = args['workspace'] != null
      ? Directory(args['workspace'] as String)
      : getWorkspaceRoot(scriptPath);

  createWorkflow(
    appPath,
    workflowName: workflowName,
    workspaceRoot: workspaceRoot,
    scriptDir: scriptDir,
  );
}
