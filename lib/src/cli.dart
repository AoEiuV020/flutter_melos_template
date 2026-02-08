import 'dart:io';

import 'package:args/args.dart';

import 'workspace.dart';

/// Validate that all required options are present. Exits with usage on failure.
void requireOptions(ArgResults args, ArgParser parser, List<String> required) {
  for (final name in required) {
    if (args[name] == null) {
      print('Error: --$name is required.\n');
      print(parser.usage);
      exit(1);
    }
  }
}

/// Resolve workspace root from --workspace arg or script path.
Directory resolveWorkspace(ArgResults args, String scriptPath) {
  return args['workspace'] != null
      ? Directory(args['workspace'] as String)
      : getWorkspaceRoot(scriptPath);
}
