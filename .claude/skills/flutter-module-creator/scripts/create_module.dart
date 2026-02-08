#!/usr/bin/env dart
/// Flutter/Dart Module Creator
///
/// Usage: dart run create_module.dart --type <type> --name <name> [options]

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'lib/app_creator.dart';
import 'lib/command.dart';
import 'lib/ffi_creator.dart';
import 'lib/package_creator.dart';
import 'lib/plugin_creator.dart';
import 'lib/workspace.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('type',
        abbr: 't',
        allowed: ['app', 'package', 'plugin', 'ffi'],
        help: 'Type of module to create',
        mandatory: true)
    ..addOption('name',
        abbr: 'n', help: 'Name of the module', mandatory: true)
    ..addFlag('console',
        help: 'Create Dart console app instead of Flutter app (app type only)',
        negatable: false)
    ..addFlag('flutter',
        help:
            'Create Flutter package instead of Dart package (package type only)',
        negatable: false)
    ..addOption('platforms',
        abbr: 'p',
        help:
            'Comma-separated platforms for plugin/ffi (e.g., android,ios,macos)')
    ..addOption('workspace',
        abbr: 'w',
        help: 'Workspace root path (auto-detected if not specified)')
    ..addFlag('no-bootstrap',
        help: 'Skip melos bootstrap after creation', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage information',
        negatable: false);

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    print(parser.usage);
    exit(1);
  }

  if (args['help'] as bool) {
    print('Flutter/Dart Module Creator\n');
    print(
        'Usage: dart run create_module.dart --type <type> --name <name> [options]\n');
    print(parser.usage);
    exit(0);
  }

  final workspaceRoot = args['workspace'] != null
      ? Directory(args['workspace'] as String)
      : getWorkspaceRoot(Platform.script.toFilePath());

  if (!File(path.join(workspaceRoot.path, 'pubspec.yaml')).existsSync()) {
    print(
        'Error: No pubspec.yaml found in workspace root: ${workspaceRoot.path}');
    exit(1);
  }

  print('Workspace root: ${workspaceRoot.path}');

  final platforms = args['platforms'] != null
      ? (args['platforms'] as String).split(',')
      : null;

  final success = switch (args['type'] as String) {
    'app' => await createApp(args['name'] as String, workspaceRoot,
        console: args['console'] as bool),
    'package' => await createPackage(args['name'] as String, workspaceRoot,
        flutter: args['flutter'] as bool),
    'plugin' => await createPlugin(args['name'] as String, workspaceRoot,
        platforms: platforms),
    'ffi' => await createFfi(args['name'] as String, workspaceRoot,
        platforms: platforms),
    _ => false,
  };

  if (!success) exit(1);

  if (!(args['no-bootstrap'] as bool)) {
    await runBootstrap(workspaceRoot);
  }

  print("\n🎉 Module '${args['name']}' created successfully!");
}
