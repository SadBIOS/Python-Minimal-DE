#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CMPLD_BIN_ROOT="$SCRIPT_ROOT/data/build_dir/compiled_binaries"

if [[ ! -d "$CMPLD_BIN_ROOT" ]] || ! find "$CMPLD_BIN_ROOT" -mindepth 1 -print -quit | grep -q .; then
    exit 0
fi



function make_env() {
    req="$1"

    if [[ "$req" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"

        match="${CMPLD_BIN_ROOT}/py_bin_${major}_${minor}_${patch}"

        if [[ ! -d "$match" ]]; then
            echo "Python $req not found." >&2
            return 1
        fi

    elif [[ "$req" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"

        mapfile -t matches < <(
            find "$CMPLD_BIN_ROOT" -maxdepth 1 -type d -name "py_bin_${major}_${minor}_*" | sort -V
        )

        if [[ ${#matches[@]} -eq 0 ]]; then
            echo "No Python $req.x builds found." >&2
            return 1
        fi

        match="${matches[-1]}"

        if [[ "$(basename "$match")" =~ ^py_bin_([0-9]+)_([0-9]+)_([0-9]+)$ ]]; then
            major="${BASH_REMATCH[1]}"
            minor="${BASH_REMATCH[2]}"
            patch="${BASH_REMATCH[3]}"
        fi
    fi

    VERMATCH_BIN_ROOT="${match}/bin"

    py=$(find "$VERMATCH_BIN_ROOT" -maxdepth 1 -type f -name "python${major}.${minor}" | head -n1)

    if [[ -z "$py" ]]; then
        echo "Python${major}.${minor} not found in $VERMATCH_BIN_ROOT" >&2
        return 1
    fi

    "$py" -m venv "venv_${major}_${minor}_${patch}"
}

# function package_parser() {}

# function pip_cache_request() {}

# function pip_install_request() {}

# function runner() {}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --init-env)
            make_env "$2"
            shift 2
            exit 0
        ;;

    esac
done