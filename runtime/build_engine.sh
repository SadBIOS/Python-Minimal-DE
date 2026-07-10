#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_CMP_DIR="$SCRIPT_ROOT/data/src_root/archives"
BUILD_DIR="$SCRIPT_ROOT/data/build_dir"

function extractor() {
    py_branch="$1"

    mkdir -p "$BUILD_DIR"

    archive=$(
        find "$SRC_CMP_DIR" -maxdepth 1 -type f -regextype posix-extended -regex ".*/Python-${py_branch}\.[0-9]+(\.tar\.xz|\.tar\.bz2|\.tar\.gz|\.tgz)$" | sort -V | tail -n1
    )

    if [[ -z "$archive" ]]; then
        echo "No source archive found for Python $py_branch"
        return 1
    fi

    case "$archive" in
        *.tar.xz)
            tar -xvJf "$archive" -C "$BUILD_DIR"
            ;;
        *.tar.bz2)
            tar -xvjf "$archive" -C "$BUILD_DIR"
            ;;
        *.tar.gz|*.tgz)
            tar -xvzf "$archive" -C "$BUILD_DIR"
            ;;
    esac
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        --extract-archive)
            extractor "$2"
            shift 2
            ;;

    esac
done