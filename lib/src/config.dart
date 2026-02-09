import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:path/path.dart' as path;

/// 从工作区根目录的 `.env` 文件加载的项目配置。
class ProjectConfig {
  final String org;
  final String? templateRepo;

  ProjectConfig._({required this.org, this.templateRepo});

  /// 从工作区根目录的 `.env` 文件加载配置。
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
