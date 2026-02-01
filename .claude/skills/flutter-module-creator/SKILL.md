---
name: flutter-module-creator
description: Create Flutter/Dart modules in Melos monorepo workspaces. Use when the user wants to create new Flutter apps, Dart packages, Flutter plugins, or FFI plugins in a Melos-managed workspace. Triggers on requests like "create a new Flutter app", "add a package", "create a plugin", "add FFI module", or any module creation in Flutter/Dart monorepos.
---

# Flutter Module Creator

Create modules in a Melos monorepo workspace with proper configuration.

## Module Types

| Type | Command | Description |
|------|---------|-------------|
| `app` | `python scripts/create_module.py app <name>` | Flutter application |
| `app --console` | `python scripts/create_module.py app <name> --console` | Dart console application |
| `package` | `python scripts/create_module.py package <name>` | Dart package |
| `package --flutter` | `python scripts/create_module.py package <name> --flutter` | Flutter package |
| `plugin` | `python scripts/create_module.py plugin <name>` | Flutter plugin |
| `ffi` | `python scripts/create_module.py ffi <name>` | Flutter FFI plugin |

## Usage Examples

```bash
# Create Flutter app
python scripts/create_module.py app my_app

# Create Dart console app
python scripts/create_module.py app my_cli --console

# Create Dart package
python scripts/create_module.py package my_utils

# Create Flutter package
python scripts/create_module.py package my_widgets --flutter

# Create plugin with specific platforms
python scripts/create_module.py plugin my_plugin --platforms android,ios

# Create FFI plugin (all platforms by default)
python scripts/create_module.py ffi my_native

# Skip melos bootstrap
python scripts/create_module.py package my_pkg --no-bootstrap
```

## Options

- `--console`: Create Dart console app (app type only)
- `--flutter`: Create Flutter package (package type only)
- `--platforms <list>`: Comma-separated platforms (plugin/ffi)
- `--workspace <path>`: Workspace root (auto-detected)
- `--no-bootstrap`: Skip melos bootstrap

## Behavior

The script automatically:
1. Detects workspace root (directory with melos/workspace in pubspec.yaml)
2. Creates module in `apps/` (apps) or `packages/` (packages/plugins/ffi)
3. Configures `analysis_options.yaml` with appropriate lints
4. Adds `resolution: workspace` to module pubspec.yaml
5. Updates root `workspace:` list in root pubspec.yaml
6. Copies LICENSE from workspace root
7. Runs `melos bootstrap`
