#!/bin/sh
. "$(dirname $0)/env.sh"

cd "$ROOT"
melos publish -y --no-dry-run
