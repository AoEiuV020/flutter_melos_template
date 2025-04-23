#!/bin/sh
. "$(dirname $0)/env.sh"

name=$1
type=$2

# name 传入了包名就在apps创建包，否则创建修改根项目，
if [ -z "$name" ] || [ "$name" = "." ]; then
    cd "$ROOT"
    rm -f pubspec.yaml README.md
    mv .gitignore .gitignore.bak
    # 删除各平台代码
    if [ "$type" = "console" ]; then
        dart create --force . "${@:3}"
    else
        rm -rf windows/ macos/ linux/ ios/ android/ web/
        flutter create --org "$organization" --project-name "$app_name" --template=app . "${@:2}"
    fi
    dart pub add dev:melos
    cat .gitignore.bak >>.gitignore
    rm -f .gitignore.bak
else
    # 检查并创建目录
    if [ ! -d "$apps_dir" ]; then
        echo "Directory $apps_dir does not exist. Creating..."
        mkdir -p "$apps_dir"
    fi
    cd "$apps_dir"
    if [ "$type" = "console" ]; then
        dart create "$name" "${@:3}"
        cd "$name"
    else
        # 删除各平台代码
        rm -rf windows/ macos/ linux/ ios/ android/ web/
        flutter create --org "$organization" --template=app "$name" "${@:2}"
        cd "$name"
    fi
fi
if [ "$type" = "console" ]; then
    echo 'include: package:lints/recommended.yaml' >analysis_options.yaml
else
    echo 'include: package:flutter_lints/flutter.yaml' >analysis_options.yaml
fi
cat "$script_dir"/analyzer_custom.yaml >>analysis_options.yaml
"$script_dir"/prepare.sh
