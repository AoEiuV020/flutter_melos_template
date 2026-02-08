#!/bin/sh
set -e
script_dir=$(cd $(dirname $0);pwd)
ROOT=$(dirname "$script_dir")
project_name=$(basename "$ROOT")
app_name=$(echo "$project_name" | tr -d '_')
apps_dir="$ROOT"/apps
packages_dir="$ROOT"/packages

# 从 .env 读取配置
if [ -f "$ROOT/.env" ]; then
  . "$ROOT/.env"
fi
organization="${ORG:-com.example}"

