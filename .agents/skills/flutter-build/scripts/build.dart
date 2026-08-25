#!/usr/bin/env dart

import 'dart:io';

import 'build_output_filter.dart';
import 'flutter_build.dart';

/// 编译 Flutter macOS 应用并过滤输出。
///
/// 用法: `dart run <script> <app_relative_path>`
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('用法: dart run <script> <app模块相对路径>');
    print('示例: dart run ... apps/video_concat_app');
    exit(1);
  }

  final appRelativePath = arguments.first;
  final appPath = Directory(appRelativePath).absolute.path;

  if (!Directory(appPath).existsSync()) {
    print('错误: 目录不存在 $appRelativePath');
    exit(1);
  }

  print('正在编译 $appRelativePath ...');

  final result = await runFlutterBuild(appPath: appPath);

  if (result.isSuccess) {
    print('编译成功');
    exit(0);
  }

  final errorSummary = filterBuildOutput(
    result.output,
    isSuccess: false,
  );

  print(errorSummary ?? '编译失败（未捕获到具体错误）');
  exit(1);
}
