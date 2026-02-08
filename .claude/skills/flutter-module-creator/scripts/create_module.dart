#!/usr/bin/env dart
/// Flutter/Dart Module Creator
///
/// Creates Flutter/Dart modules in a Melos monorepo workspace with proper configuration.
///
/// Supported module types:
/// - app: Flutter application (default) or Dart console application
/// - package: Dart/Flutter package
/// - plugin: Flutter plugin with platform support
/// - ffi: Flutter FFI plugin with native code support
///
/// Usage:
///     dart run create_module.dart <type> <name> [options]
///
/// Examples:
///     dart run create_module.dart app my_app
///     dart run create_module.dart app my_console --console
///     dart run create_module.dart package my_utils
///     dart run create_module.dart package my_flutter_pkg --flutter
///     dart run create_module.dart plugin my_plugin --platforms android,ios
///     dart run create_module.dart ffi my_native --platforms android,ios,macos,windows,linux

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// Find the workspace root by looking for pubspec.yaml with melos config.
Directory findWorkspaceRoot() {
  var current = Directory.current;
  while (true) {
    final pubspec = File(path.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (content.contains('melos:') || content.contains('workspace:')) {
        return current;
      }
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current;
}

/// Extract organization from existing modules or use default.
String getOrganization(Directory workspaceRoot) {
  for (final subdir in ['apps', 'packages']) {
    final dirPath = Directory(path.join(workspaceRoot.path, subdir));
    if (dirPath.existsSync()) {
      for (final module in dirPath.listSync().whereType<Directory>()) {
        final androidManifest = File(path.join(
          module.path,
          'android',
          'app',
          'src',
          'main',
          'AndroidManifest.xml',
        ));
        if (androidManifest.existsSync()) {
          final content = androidManifest.readAsStringSync();
          final match = RegExp(r'package="([^"]+)"').firstMatch(content);
          if (match != null) {
            final parts = match.group(1)!.split('.');
            if (parts.length > 1) {
              parts.removeLast();
              return parts.join('.');
            }
          }
        }
      }
    }
  }
  return 'com.example';
}

/// Run a command and return success status.
Future<bool> runCommand(
  List<String> cmd, {
  String? workingDirectory,
  bool verbose = false,
}) async {
  try {
    if (verbose) {
      print('Running: ${cmd.join(' ')}');
    }
    final result = await Process.run(
      cmd.first,
      cmd.skip(1).toList(),
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      print('Error: ${result.stderr}');
      return false;
    }
    if (verbose && result.stdout.toString().isNotEmpty) {
      print(result.stdout);
    }
    return true;
  } catch (e) {
    print('Error running command: $e');
    return false;
  }
}

/// Update analysis_options.yaml by copying from workspace root and adjusting the include line.
void updateAnalysisOptions(
  Directory modulePath,
  Directory workspaceRoot, {
  bool useFlutter = true,
}) {
  final rootAnalysis =
      File(path.join(workspaceRoot.path, 'analysis_options.yaml'));
  if (!rootAnalysis.existsSync()) {
    print('Warning: No analysis_options.yaml found in workspace root');
    return;
  }

  final lines = rootAnalysis.readAsLinesSync();
  if (lines.isNotEmpty && lines.first.startsWith('include:')) {
    lines[0] = useFlutter
        ? 'include: package:flutter_lints/flutter.yaml'
        : 'include: package:lints/recommended.yaml';
  }

  final analysisFile =
      File(path.join(modulePath.path, 'analysis_options.yaml'));
  analysisFile.writeAsStringSync('${lines.join('\n')}\n');
}

/// Add resolution: workspace to module pubspec.yaml.
bool updateModulePubspec(Directory modulePath) {
  final pubspecFile = File(path.join(modulePath.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found in ${modulePath.path}');
    return false;
  }

  var content = pubspecFile.readAsStringSync();
  if (content.contains('resolution:')) {
    return true;
  }

  final lines = content.split('\n');
  final updatedLines = <String>[];
  var resolutionAdded = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    updatedLines.add(line);

    if (!resolutionAdded && line.trim().startsWith('environment:')) {
      final indent = line.substring(0, line.length - line.trimLeft().length);
      // Skip environment content
      var j = i + 1;
      while (j < lines.length) {
        final nextLine = lines[j];
        if (nextLine.trim().isNotEmpty &&
            !nextLine.startsWith('$indent  ')) {
          break;
        }
        updatedLines.add(nextLine);
        j++;
      }
      // Add resolution
      updatedLines.add('');
      updatedLines.add('${indent}resolution: workspace');
      resolutionAdded = true;
      i = j - 1; // Adjust index
    }
  }

  pubspecFile.writeAsStringSync(updatedLines.join('\n'));
  return true;
}

/// Add module to workspace pubspec.yaml.
bool updateWorkspacePubspec(Directory workspaceRoot, String moduleRelPath) {
  final pubspecFile = File(path.join(workspaceRoot.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    return false;
  }

  final content = pubspecFile.readAsStringSync();
  final lines = content.split('\n');

  // Collect existing workspace entries
  final workspaceEntries = <String>{};
  var inWorkspace = false;
  var workspaceStart = -1;
  var workspaceEnd = -1;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().startsWith('workspace:')) {
      inWorkspace = true;
      workspaceStart = i;
      continue;
    }
    if (inWorkspace) {
      final stripped = line.trim();
      if (stripped.startsWith('- ')) {
        final entryPath = stripped.substring(2).trim();
        workspaceEntries.add(entryPath);
        workspaceEnd = i;
      } else if (stripped.isNotEmpty && !line.startsWith('  ')) {
        inWorkspace = false;
      }
    }
  }

  // Normalize and add new entry
  moduleRelPath = moduleRelPath.replaceAll('\\', '/');
  workspaceEntries.add(moduleRelPath);
  final sortedEntries = workspaceEntries.toList()..sort();

  // Rebuild content
  final newLines = <String>[];
  if (workspaceStart >= 0) {
    // Remove old workspace section
    newLines.addAll(lines.sublist(0, workspaceStart));
    // Add updated workspace
    newLines.add('workspace:');
    for (final entry in sortedEntries) {
      newLines.add('  - $entry');
    }
    // Add remaining content
    final remainingStart = workspaceEnd >= 0 ? workspaceEnd + 1 : workspaceStart + 1;
    if (remainingStart < lines.length) {
      newLines.addAll(lines.sublist(remainingStart));
    }
  } else {
    // Find environment section and add workspace after it
    var envFound = false;
    var envEnd = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('environment:') && !envFound) {
        envFound = true;
        newLines.add(line);
        // Skip environment content
        var j = i + 1;
        while (j < lines.length) {
          if (lines[j].trim().isNotEmpty && !lines[j].startsWith('  ')) {
            break;
          }
          newLines.add(lines[j]);
          j++;
        }
        envEnd = j;
        // Add workspace
        newLines.add('');
        newLines.add('workspace:');
        for (final entry in sortedEntries) {
          newLines.add('  - $entry');
        }
        newLines.add('');
        i = j - 1;
      } else if (!envFound || i >= envEnd) {
        newLines.add(line);
      }
    }
  }

  pubspecFile.writeAsStringSync(newLines.join('\n'));
  return true;
}

/// Copy LICENSE file from workspace root if exists.
void copyLicense(Directory workspaceRoot, Directory modulePath) {
  final licenseFile = File(path.join(workspaceRoot.path, 'LICENSE'));
  if (licenseFile.existsSync()) {
    final destFile = File(path.join(modulePath.path, 'LICENSE'));
    destFile.writeAsStringSync(licenseFile.readAsStringSync());
  }
}

/// Remove platform directories that might interfere with creation.
void removePlatformDirs(Directory dir) {
  for (final platform in [
    'windows',
    'macos',
    'linux',
    'ios',
    'android',
    'web'
  ]) {
    final platformDir = Directory(path.join(dir.path, platform));
    if (platformDir.existsSync()) {
      platformDir.deleteSync(recursive: true);
    }
  }
}

/// Create a Flutter app or Dart console application.
Future<bool> createApp(
  String name,
  Directory workspaceRoot, {
  bool console = false,
  List<String>? extraArgs,
}) async {
  final appsDir = Directory(path.join(workspaceRoot.path, 'apps'));
  if (!appsDir.existsSync()) {
    appsDir.createSync(recursive: true);
  }

  final org = getOrganization(workspaceRoot);
  final modulePath = Directory(path.join(appsDir.path, name));

  if (console) {
    // Dart console app
    final cmd = ['dart', 'create', name, ...?extraArgs];
    if (!await runCommand(cmd, workingDirectory: appsDir.path)) {
      return false;
    }
    updateAnalysisOptions(modulePath, workspaceRoot, useFlutter: false);
  } else {
    // Flutter app
    removePlatformDirs(appsDir);
    final cmd = [
      'flutter',
      'create',
      '--org',
      org,
      '--template=app',
      name,
      ...?extraArgs
    ];
    if (!await runCommand(cmd, workingDirectory: appsDir.path)) {
      return false;
    }
    updateAnalysisOptions(modulePath, workspaceRoot, useFlutter: true);
  }

  updateModulePubspec(modulePath);
  updateWorkspacePubspec(workspaceRoot, 'apps/$name');

  print('✅ Created app: ${modulePath.path}');
  return true;
}

/// Create a Dart or Flutter package.
Future<bool> createPackage(
  String name,
  Directory workspaceRoot, {
  bool flutter = false,
  List<String>? extraArgs,
}) async {
  final packagesDir = Directory(path.join(workspaceRoot.path, 'packages'));
  if (!packagesDir.existsSync()) {
    packagesDir.createSync(recursive: true);
  }

  final modulePath = Directory(path.join(packagesDir.path, name));

  final cmd = flutter
      ? ['flutter', 'create', '--template=package', name, ...?extraArgs]
      : ['dart', 'create', '--template=package', name, ...?extraArgs];

  if (!await runCommand(cmd, workingDirectory: packagesDir.path)) {
    return false;
  }

  copyLicense(workspaceRoot, modulePath);
  updateAnalysisOptions(modulePath, workspaceRoot, useFlutter: flutter);
  updateModulePubspec(modulePath);
  updateWorkspacePubspec(workspaceRoot, 'packages/$name');

  print('✅ Created package: ${modulePath.path}');
  return true;
}

/// Create a Flutter plugin.
Future<bool> createPlugin(
  String name,
  Directory workspaceRoot, {
  List<String>? platforms,
  List<String>? extraArgs,
}) async {
  final packagesDir = Directory(path.join(workspaceRoot.path, 'packages'));
  if (!packagesDir.existsSync()) {
    packagesDir.createSync(recursive: true);
  }

  final org = getOrganization(workspaceRoot);
  final modulePath = Directory(path.join(packagesDir.path, name));

  removePlatformDirs(packagesDir);

  final cmd = [
    'flutter',
    'create',
    '--org',
    org,
    '--template=plugin',
    name,
  ];
  if (platforms != null && platforms.isNotEmpty) {
    cmd.addAll(['--platforms', platforms.join(',')]);
  }
  if (extraArgs != null) {
    cmd.addAll(extraArgs);
  }

  if (!await runCommand(cmd, workingDirectory: packagesDir.path)) {
    return false;
  }

  copyLicense(workspaceRoot, modulePath);
  updateAnalysisOptions(modulePath, workspaceRoot, useFlutter: true);
  updateModulePubspec(modulePath);
  updateWorkspacePubspec(workspaceRoot, 'packages/$name');

  print('✅ Created plugin: ${modulePath.path}');
  return true;
}

/// Create a Flutter FFI plugin.
Future<bool> createFfi(
  String name,
  Directory workspaceRoot, {
  List<String>? platforms,
  List<String>? extraArgs,
}) async {
  final packagesDir = Directory(path.join(workspaceRoot.path, 'packages'));
  if (!packagesDir.existsSync()) {
    packagesDir.createSync(recursive: true);
  }

  final org = getOrganization(workspaceRoot);
  final modulePath = Directory(path.join(packagesDir.path, name));

  const defaultPlatforms = ['android', 'ios', 'windows', 'macos', 'linux'];
  platforms ??= defaultPlatforms;

  removePlatformDirs(packagesDir);

  final cmd = [
    'flutter',
    'create',
    '--org',
    org,
    '--template=plugin_ffi',
    '--platforms',
    platforms.join(','),
    name,
    ...?extraArgs,
  ];

  if (!await runCommand(cmd, workingDirectory: packagesDir.path)) {
    return false;
  }

  copyLicense(workspaceRoot, modulePath);
  updateAnalysisOptions(modulePath, workspaceRoot, useFlutter: true);
  updateModulePubspec(modulePath);
  updateWorkspacePubspec(workspaceRoot, 'packages/$name');

  print('✅ Created FFI plugin: ${modulePath.path}');
  return true;
}

/// Run melos bootstrap to update dependencies.
Future<bool> runBootstrap(Directory workspaceRoot) async {
  print('Running melos bootstrap...');
  final result = await Process.run(
    'melos',
    ['bootstrap'],
    workingDirectory: workspaceRoot.path,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    print('Warning: melos bootstrap failed: ${result.stderr}');
    return false;
  }
  print('✅ melos bootstrap completed');
  return true;
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'type',
      abbr: 't',
      allowed: ['app', 'package', 'plugin', 'ffi'],
      help: 'Type of module to create',
      mandatory: true,
    )
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Name of the module',
      mandatory: true,
    )
    ..addFlag(
      'console',
      help: 'Create Dart console app instead of Flutter app (app type only)',
      negatable: false,
    )
    ..addFlag(
      'flutter',
      help: 'Create Flutter package instead of Dart package (package type only)',
      negatable: false,
    )
    ..addOption(
      'platforms',
      abbr: 'p',
      help: 'Comma-separated platforms for plugin/ffi (e.g., android,ios,macos)',
    )
    ..addOption(
      'workspace',
      abbr: 'w',
      help: 'Workspace root path (auto-detected if not specified)',
    )
    ..addFlag(
      'no-bootstrap',
      help: 'Skip melos bootstrap after creation',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information',
      negatable: false,
    );

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e\n');
    print(parser.usage);
    exit(1);
  }

  if (args['help'] as bool) {
    print('Flutter/Dart Module Creator');
    print('');
    print('Usage: dart run create_module.dart --type <type> --name <name> [options]');
    print('');
    print(parser.usage);
    exit(0);
  }

  final moduleType = args['type'] as String;
  final moduleName = args['name'] as String;

  // Find workspace root
  final workspaceRoot = args['workspace'] != null
      ? Directory(args['workspace'] as String)
      : findWorkspaceRoot();

  final pubspecFile = File(path.join(workspaceRoot.path, 'pubspec.yaml'));
  if (!pubspecFile.existsSync()) {
    print('Error: No pubspec.yaml found in workspace root: ${workspaceRoot.path}');
    exit(1);
  }

  print('Workspace root: ${workspaceRoot.path}');

  // Parse platforms
  final platforms = args['platforms'] != null
      ? (args['platforms'] as String).split(',')
      : null;

  // Create module based on type
  var success = false;
  switch (moduleType) {
    case 'app':
      success = await createApp(
        moduleName,
        workspaceRoot,
        console: args['console'] as bool,
      );
      break;
    case 'package':
      success = await createPackage(
        moduleName,
        workspaceRoot,
        flutter: args['flutter'] as bool,
      );
      break;
    case 'plugin':
      success = await createPlugin(
        moduleName,
        workspaceRoot,
        platforms: platforms,
      );
      break;
    case 'ffi':
      success = await createFfi(
        moduleName,
        workspaceRoot,
        platforms: platforms,
      );
      break;
  }

  if (!success) {
    exit(1);
  }

  // Run melos bootstrap
  if (!(args['no-bootstrap'] as bool)) {
    await runBootstrap(workspaceRoot);
  }

  print("\n🎉 Module '$moduleName' created successfully!");
}
