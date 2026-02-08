import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;

/// Project configuration loaded from `.env` at workspace root.
class ProjectConfig {
  final String org;
  final String? templateRepo;

  ProjectConfig._({required this.org, this.templateRepo});

  /// Load config from workspace root's `.env` file.
  factory ProjectConfig(Directory workspaceRoot) {
    final envPath = path.join(workspaceRoot.path, '.env');
    final env = DotEnv();
    if (File(envPath).existsSync()) {
      env.load([envPath]);
    }
    return ProjectConfig._(
      org: env['ORG'] ?? 'com.example',
      templateRepo: env['TEMPLATE_REPO'],
    );
  }
}
