---
name: flutter-workflow
description: Create GitHub Actions CI/CD workflow for Flutter apps in Melos workspace. Use when user wants to add CI/CD, create build workflow, setup GitHub Actions, or automate Flutter app builds. Supports all platforms (Android, iOS, Web, Linux, Windows, macOS).
---

# Flutter Workflow Creator

Create GitHub Actions workflow for Flutter app builds.

## Usage

```bash
python scripts/create_workflow.py <app_path> [--name <filename>]
```

## Examples

```bash
# Create workflow for app
python scripts/create_workflow.py apps/my_app

# Custom workflow filename
python scripts/create_workflow.py apps/my_app --name ci.yml
```

## Options

- `app_path`: App module path (e.g., `apps/my_app`)
- `--name`: Workflow filename (default: `main.yml`)
- `--workspace`: Workspace root path (auto-detected)

## Template Features

- Multi-platform builds: Android (APK/AAB), iOS, macOS, Windows, Linux, Web
- Automatic version detection from git tags
- Release creation on tag push
- Web deployment to GitHub Pages
- Melos workspace support
