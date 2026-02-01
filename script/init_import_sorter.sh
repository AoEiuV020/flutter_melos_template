#!/bin/sh
. "$(dirname $0)/env.sh"

# 检查是否安装了 import_sorter
if ! dart pub global list |grep import_sorter > /dev/null; then
    echo "import_sorter is not installed. Installing..."
    dart pub global activate --source git https://github.com/myConsciousness/import_sorter.git --git-ref fix/monorepo-pub-workspaces
fi
