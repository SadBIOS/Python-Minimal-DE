#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CMPLD_BIN_ROOT="$SCRIPT_ROOT/data/build_dir/compiled_binaries/"