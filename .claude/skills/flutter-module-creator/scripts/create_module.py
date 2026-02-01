#!/usr/bin/env python3
"""
Flutter/Dart Module Creator

Creates Flutter/Dart modules in a Melos monorepo workspace with proper configuration.

Supported module types:
- app: Flutter application (default) or Dart console application
- package: Dart/Flutter package
- plugin: Flutter plugin with platform support
- ffi: Flutter FFI plugin with native code support

Usage:
    python create_module.py <type> <name> [options]

Examples:
    python create_module.py app my_app
    python create_module.py app my_console --console
    python create_module.py package my_utils
    python create_module.py package my_flutter_pkg --flutter
    python create_module.py plugin my_plugin --platforms android,ios
    python create_module.py ffi my_native --platforms android,ios,macos,windows,linux
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


def find_workspace_root() -> Path:
    """Find the workspace root by looking for pubspec.yaml with melos config."""
    current = Path.cwd()
    while current != current.parent:
        pubspec = current / "pubspec.yaml"
        if pubspec.exists():
            content = pubspec.read_text()
            if "melos:" in content or "workspace:" in content:
                return current
        current = current.parent
    return Path.cwd()


def get_organization(workspace_root: Path) -> str:
    """Extract organization from existing modules or use default."""
    # Try to find org from existing modules
    for subdir in ["apps", "packages"]:
        dir_path = workspace_root / subdir
        if dir_path.exists():
            for module in dir_path.iterdir():
                if module.is_dir():
                    android_manifest = module / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
                    if android_manifest.exists():
                        content = android_manifest.read_text()
                        match = re.search(r'package="([^"]+)"', content)
                        if match:
                            parts = match.group(1).rsplit(".", 1)
                            if len(parts) > 1:
                                return parts[0]
    return "com.example"


def run_command(cmd: list[str], cwd: Path | None = None) -> bool:
    """Run a command and return success status."""
    try:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error: {result.stderr}")
            return False
        return True
    except Exception as e:
        print(f"Error running command: {e}")
        return False


def update_analysis_options(module_path: Path, use_flutter: bool = True):
    """Update analysis_options.yaml with appropriate linter config."""
    analysis_file = module_path / "analysis_options.yaml"
    if use_flutter:
        content = "include: package:flutter_lints/flutter.yaml\n"
    else:
        content = "include: package:lints/recommended.yaml\n"
    
    # Add custom analyzer rules
    content += """
analyzer:
  errors:
    asset_directory_does_not_exist: error
    argument_type_not_assignable: warning
    prefer_relative_imports: error
linter:
  rules:
    - prefer_relative_imports
"""
    analysis_file.write_text(content)


def update_module_pubspec(module_path: Path):
    """Add resolution: workspace to module pubspec.yaml."""
    pubspec_file = module_path / "pubspec.yaml"
    if not pubspec_file.exists():
        print(f"Error: pubspec.yaml not found in {module_path}")
        return False
    
    content = pubspec_file.read_text()
    if "resolution:" in content:
        return True
    
    lines = content.split("\n")
    updated_lines = []
    resolution_added = False
    
    for i, line in enumerate(lines):
        updated_lines.append(line)
        if not resolution_added and line.strip().startswith("environment:"):
            # Find the indentation
            indent = line[:len(line) - len(line.lstrip())]
            # Skip environment content
            j = i + 1
            while j < len(lines):
                next_line = lines[j]
                if next_line.strip() and not next_line.startswith(indent + "  "):
                    break
                updated_lines.append(next_line)
                j += 1
            # Add resolution
            updated_lines.append("")
            updated_lines.append(f"{indent}resolution: workspace")
            resolution_added = True
            # Skip the lines we already added
            for _ in range(j - i - 1):
                lines.pop(i + 1)
    
    pubspec_file.write_text("\n".join(updated_lines))
    return True


def update_workspace_pubspec(workspace_root: Path, module_rel_path: str):
    """Add module to workspace pubspec.yaml."""
    pubspec_file = workspace_root / "pubspec.yaml"
    if not pubspec_file.exists():
        return False
    
    content = pubspec_file.read_text()
    lines = content.split("\n")
    
    # Collect existing workspace entries
    workspace_entries = set()
    in_workspace = False
    workspace_start = -1
    workspace_end = -1
    
    for i, line in enumerate(lines):
        if line.strip().startswith("workspace:"):
            in_workspace = True
            workspace_start = i
            continue
        if in_workspace:
            stripped = line.strip()
            if stripped.startswith("- "):
                path = stripped[2:].strip()
                workspace_entries.add(path)
                workspace_end = i
            elif stripped and not line.startswith("  "):
                in_workspace = False
    
    # Normalize and add new entry
    module_rel_path = module_rel_path.replace("\\", "/")
    workspace_entries.add(module_rel_path)
    sorted_entries = sorted(workspace_entries)
    
    # Rebuild content
    if workspace_start >= 0:
        # Remove old workspace section
        new_lines = lines[:workspace_start]
        # Add updated workspace
        new_lines.append("workspace:")
        for entry in sorted_entries:
            new_lines.append(f"  - {entry}")
        # Add remaining content
        remaining_start = workspace_end + 1 if workspace_end >= 0 else workspace_start + 1
        if remaining_start < len(lines):
            new_lines.extend(lines[remaining_start:])
    else:
        # Find environment section and add workspace after it
        new_lines = []
        env_found = False
        env_end = -1
        for i, line in enumerate(lines):
            if line.strip().startswith("environment:") and not env_found:
                env_found = True
                new_lines.append(line)
                # Skip environment content
                j = i + 1
                while j < len(lines):
                    if lines[j].strip() and not lines[j].startswith("  "):
                        break
                    new_lines.append(lines[j])
                    j += 1
                env_end = j
                # Add workspace
                new_lines.append("")
                new_lines.append("workspace:")
                for entry in sorted_entries:
                    new_lines.append(f"  - {entry}")
                new_lines.append("")
            elif env_found and i < env_end:
                # Skip lines already added
                continue
            else:
                new_lines.append(line)
    
    pubspec_file.write_text("\n".join(new_lines))
    return True


def copy_license(workspace_root: Path, module_path: Path):
    """Copy LICENSE file from workspace root if exists."""
    license_file = workspace_root / "LICENSE"
    if license_file.exists():
        (module_path / "LICENSE").write_text(license_file.read_text())


def remove_platform_dirs(module_path: Path):
    """Remove platform directories that might interfere with creation."""
    for platform in ["windows", "macos", "linux", "ios", "android", "web"]:
        platform_dir = module_path / platform
        if platform_dir.exists():
            import shutil
            shutil.rmtree(platform_dir)


def create_app(name: str, workspace_root: Path, console: bool = False, extra_args: list = None):
    """Create a Flutter app or Dart console application."""
    apps_dir = workspace_root / "apps"
    apps_dir.mkdir(exist_ok=True)
    
    org = get_organization(workspace_root)
    module_path = apps_dir / name
    
    if console:
        # Dart console app
        if not run_command(["dart", "create", name] + (extra_args or []), cwd=apps_dir):
            return False
        update_analysis_options(module_path, use_flutter=False)
    else:
        # Flutter app
        remove_platform_dirs(apps_dir)
        cmd = ["flutter", "create", "--org", org, "--template=app", name]
        if extra_args:
            cmd.extend(extra_args)
        if not run_command(cmd, cwd=apps_dir):
            return False
        update_analysis_options(module_path, use_flutter=True)
    
    update_module_pubspec(module_path)
    update_workspace_pubspec(workspace_root, f"apps/{name}")
    
    print(f"✅ Created app: {module_path}")
    return True


def create_package(name: str, workspace_root: Path, flutter: bool = False, extra_args: list = None):
    """Create a Dart or Flutter package."""
    packages_dir = workspace_root / "packages"
    packages_dir.mkdir(exist_ok=True)
    
    module_path = packages_dir / name
    
    if flutter:
        cmd = ["flutter", "create", "--template=package", name]
    else:
        cmd = ["dart", "create", "--template=package", name]
    
    if extra_args:
        cmd.extend(extra_args)
    
    if not run_command(cmd, cwd=packages_dir):
        return False
    
    copy_license(workspace_root, module_path)
    update_analysis_options(module_path, use_flutter=flutter)
    update_module_pubspec(module_path)
    update_workspace_pubspec(workspace_root, f"packages/{name}")
    
    print(f"✅ Created package: {module_path}")
    return True


def create_plugin(name: str, workspace_root: Path, platforms: list = None, extra_args: list = None):
    """Create a Flutter plugin."""
    packages_dir = workspace_root / "packages"
    packages_dir.mkdir(exist_ok=True)
    
    org = get_organization(workspace_root)
    module_path = packages_dir / name
    
    remove_platform_dirs(packages_dir)
    
    cmd = ["flutter", "create", "--org", org, "--template=plugin", name]
    if platforms:
        cmd.extend(["--platforms", ",".join(platforms)])
    if extra_args:
        cmd.extend(extra_args)
    
    if not run_command(cmd, cwd=packages_dir):
        return False
    
    copy_license(workspace_root, module_path)
    update_analysis_options(module_path, use_flutter=True)
    update_module_pubspec(module_path)
    update_workspace_pubspec(workspace_root, f"packages/{name}")
    
    print(f"✅ Created plugin: {module_path}")
    return True


def create_ffi(name: str, workspace_root: Path, platforms: list = None, extra_args: list = None):
    """Create a Flutter FFI plugin."""
    packages_dir = workspace_root / "packages"
    packages_dir.mkdir(exist_ok=True)
    
    org = get_organization(workspace_root)
    module_path = packages_dir / name
    
    default_platforms = ["android", "ios", "windows", "macos", "linux"]
    platforms = platforms or default_platforms
    
    remove_platform_dirs(packages_dir)
    
    cmd = ["flutter", "create", "--org", org, "--template=plugin_ffi", 
           "--platforms", ",".join(platforms), name]
    if extra_args:
        cmd.extend(extra_args)
    
    if not run_command(cmd, cwd=packages_dir):
        return False
    
    copy_license(workspace_root, module_path)
    update_analysis_options(module_path, use_flutter=True)
    update_module_pubspec(module_path)
    update_workspace_pubspec(workspace_root, f"packages/{name}")
    
    print(f"✅ Created FFI plugin: {module_path}")
    return True


def run_bootstrap(workspace_root: Path):
    """Run melos bootstrap to update dependencies."""
    print("Running melos bootstrap...")
    result = subprocess.run(["melos", "bootstrap"], cwd=workspace_root, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Warning: melos bootstrap failed: {result.stderr}")
        return False
    print("✅ melos bootstrap completed")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Create Flutter/Dart modules in a Melos monorepo workspace"
    )
    parser.add_argument("type", choices=["app", "package", "plugin", "ffi"],
                       help="Type of module to create")
    parser.add_argument("name", help="Name of the module")
    parser.add_argument("--console", action="store_true",
                       help="Create Dart console app instead of Flutter app (app type only)")
    parser.add_argument("--flutter", action="store_true",
                       help="Create Flutter package instead of Dart package (package type only)")
    parser.add_argument("--platforms", type=str,
                       help="Comma-separated platforms for plugin/ffi (e.g., android,ios,macos)")
    parser.add_argument("--workspace", type=str,
                       help="Workspace root path (auto-detected if not specified)")
    parser.add_argument("--no-bootstrap", action="store_true",
                       help="Skip melos bootstrap after creation")
    
    args, extra_args = parser.parse_known_args()
    
    # Find workspace root
    if args.workspace:
        workspace_root = Path(args.workspace)
    else:
        workspace_root = find_workspace_root()
    
    if not (workspace_root / "pubspec.yaml").exists():
        print(f"Error: No pubspec.yaml found in workspace root: {workspace_root}")
        sys.exit(1)
    
    print(f"Workspace root: {workspace_root}")
    
    # Parse platforms
    platforms = args.platforms.split(",") if args.platforms else None
    
    # Create module based on type
    success = False
    if args.type == "app":
        success = create_app(args.name, workspace_root, console=args.console, extra_args=extra_args)
    elif args.type == "package":
        success = create_package(args.name, workspace_root, flutter=args.flutter, extra_args=extra_args)
    elif args.type == "plugin":
        success = create_plugin(args.name, workspace_root, platforms=platforms, extra_args=extra_args)
    elif args.type == "ffi":
        success = create_ffi(args.name, workspace_root, platforms=platforms, extra_args=extra_args)
    
    if not success:
        sys.exit(1)
    
    # Run melos bootstrap
    if not args.no_bootstrap:
        run_bootstrap(workspace_root)
    
    print(f"\n🎉 Module '{args.name}' created successfully!")


if __name__ == "__main__":
    main()
