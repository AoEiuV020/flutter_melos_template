#!/bin/sh
. "$(dirname $0)/env.sh"

name=$1
# name 传入了包名就在packages创建包，否则创建修改根项目，
if [ -z "$name" ] || [ "$name" = "." ]; then
    cd "$ROOT"
    rm -f pubspec.yaml README.md
    mv .gitignore .gitignore.bak
    # 删除各平台代码
    rm -rf windows/ macos/ linux/ ios/ android/ web/
    flutter create --org "$organization" --project-name "$project_name" --template=plugin . "${@:2}"
    dart pub add dev:melos
    cat .gitignore.bak >>.gitignore
    rm -f .gitignore.bak
else
    # 检查并创建目录
    if [ ! -d "$packages_dir" ]; then
        echo "Directory $packages_dir does not exist. Creating..."
        mkdir -p "$packages_dir"
    fi
    cd "$packages_dir"
    # 删除各平台代码
    rm -rf windows/ macos/ linux/ ios/ android/ web/
    flutter create --org "$organization" --template=plugin "$name" "${@:2}"
    cd "$name"
    cp "$ROOT/LICENSE" .
fi
echo 'include: package:flutter_lints/flutter.yaml' >analysis_options.yaml
cat "$script_dir"/analyzer_custom.yaml >>analysis_options.yaml
"$script_dir"/prepare.sh
