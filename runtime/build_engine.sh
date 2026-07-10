#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_CMP_DIR="$SCRIPT_ROOT/data/src_root/archives"
BUILD_DIR="$SCRIPT_ROOT/data/build_dir"
BIN_ROOT="$SCRIPT_ROOT/data/build_dir/compiled_binaries"
BIN_PATHS="$SCRIPT_ROOT/data/build_dir/bin_paths.txt"

VERSION_PARAM=""

mkdir -pv "$BIN_ROOT"
touch "$BIN_PATHS"

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

    filename=$(basename "$archive")

    exact_version="${filename#Python-}"
    exact_version="${exact_version%.tar.*}"
    exact_version="${exact_version%.tgz}"

    VERSION_PARAM="${exact_version//./_}"

    target_bin_dir="${BIN_ROOT}/py_bin_${VERSION_PARAM}"
    mkdir -pv "$target_bin_dir"

    echo "<|>${exact_version}<|>${target_bin_dir}/<|>" >> "$BIN_PATHS"

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

function clean_cache() {
    truncate -s 0 "$BIN_PATHS"
    
    echo "Removing extracted Python source directories..."
    if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
        rm -vrf "$BUILD_DIR"/Python-[0-9]*
    fi
}

function clean_bins() {
    echo "Removing compiled binary directories..."
    if [[ -n "$BIN_ROOT" && -d "$BIN_ROOT" ]]; then
        rm -vrf "$BIN_ROOT"/py_bin_*
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --extract-archive)
            extractor "$2"
            exit 0
        ;;

        --wipe-cache)
            clean_cache
            exit 0
        ;;

        --nuke)
            clean_cache
            clean_bins
            exit 0
        ;;

    esac
done