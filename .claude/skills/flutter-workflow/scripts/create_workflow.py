#!/usr/bin/env python3
"""
Create GitHub Actions workflow for Flutter app in Melos workspace.

Usage:
    python create_workflow.py <app_path> [--name <workflow_name>]

Examples:
    python create_workflow.py apps/my_app
    python create_workflow.py apps/my_app --name ci.yml
"""

import argparse
import os
import re
import shutil
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


def create_workflow(app_path: str, workflow_name: str = "main.yml", workspace_root: Path = None):
    """Create workflow file from template."""
    if workspace_root is None:
        workspace_root = find_workspace_root()
    
    # Normalize app path
    app_path = app_path.rstrip("/")
    if not app_path.startswith("apps/") and not app_path.startswith("packages/"):
        # Assume it's under apps/
        if "/" not in app_path:
            app_path = f"apps/{app_path}"
    
    # Check if app exists
    full_app_path = workspace_root / app_path
    if not full_app_path.exists():
        print(f"Error: App path does not exist: {full_app_path}")
        sys.exit(1)
    
    # Locate template
    script_dir = Path(__file__).parent
    template_path = script_dir.parent / "assets" / "main.yml.template"
    
    if not template_path.exists():
        print(f"Error: Template not found: {template_path}")
        sys.exit(1)
    
    # Read template
    content = template_path.read_text()
    
    # Replace placeholder with app path
    content = content.replace("apps/__APP_NAME__", app_path)
    
    # Create .github/workflows directory
    workflows_dir = workspace_root / ".github" / "workflows"
    workflows_dir.mkdir(parents=True, exist_ok=True)
    
    # Write workflow file
    output_path = workflows_dir / workflow_name
    output_path.write_text(content)
    
    print(f"✅ Created workflow: {output_path}")
    print(f"   App path: {app_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Create GitHub Actions workflow for Flutter app"
    )
    parser.add_argument("app_path", help="Path to the app (e.g., apps/my_app)")
    parser.add_argument("--name", default="main.yml", 
                       help="Workflow filename (default: main.yml)")
    parser.add_argument("--workspace", type=str,
                       help="Workspace root path (auto-detected if not specified)")
    
    args = parser.parse_args()
    
    workspace_root = Path(args.workspace) if args.workspace else None
    create_workflow(args.app_path, args.name, workspace_root)


if __name__ == "__main__":
    main()
