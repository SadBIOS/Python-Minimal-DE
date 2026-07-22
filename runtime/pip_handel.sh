#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

ACTION=""
PKG_LIST_PATH=""
PIP_BIN_SRC=""
LOCAL_PKG_ROOT=""

function req_processor() {
    pkg_list="$1"
    pip_cmd="$2"
    pkg_root="${3%/}"

    if [[ ! -f "$pkg_list" ]]; then
        echo "Package list $pkg_list not found." >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//[$'\r ']/}"

        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi

        if [[ "$line" =~ ^([^=]+)==(.*)$ ]]; then
            pkg="${BASH_REMATCH[1]}"
            ver="${BASH_REMATCH[2]}"
            dest_ver="v_${ver//./_}"
        else
            pkg="$line"
            dest_ver="latest"
        fi

        dest_dir="${pkg_root}/${pkg}/${dest_ver}"
        
        mkdir -p "$dest_dir"
        $pip_cmd --disable-pip-version-check --no-cache-dir download "$line" --dest "$dest_dir"

    done < "$pkg_list"
}

function req_resolver() {
    pkg_list="$1"
    pip_cmd="$2"
    pkg_root="${3%/}"

    if [[ ! -f "$pkg_list" ]]; then
        echo "Package list $pkg_list not found." >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//[$'\r ']/}"
        
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi

        if [[ "$line" =~ ^([^=]+)==(.*)$ ]]; then
            pkg="${BASH_REMATCH[1]}"
            ver="${BASH_REMATCH[2]}"
            dest_ver="v_${ver//./_}"
        else
            pkg="$line"
            dest_ver="latest"
        fi

        dest_dir="${pkg_root}/${pkg}/${dest_ver}"

        if [[ ! -d "$dest_dir" ]]; then
            echo "Directory $dest_dir not found. Did you run --cache-pip?" >&2
            continue
        fi

        $pip_cmd install --disable-pip-version-check --no-index --find-links "$dest_dir" "$line"

    done < "$pkg_list"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pkglist-path)
            PKG_LIST_PATH="$2"
            shift 2
        ;;

        --pip-bin-src)
            PIP_BIN_SRC="$2"
            shift 2
        ;;

        --local-package-root)
            LOCAL_PKG_ROOT="$2"
            shift 2
        ;;

        --cache-pip)
            req_processor "$PKG_LIST_PATH" "$PIP_BIN_SRC" "$LOCAL_PKG_ROOT"
            shift
            exit 0
        ;;

        --resolve-pip)
            req_resolver "$PKG_LIST_PATH" "$PIP_BIN_SRC" "$LOCAL_PKG_ROOT"
            shift
            exit 0
        ;;

    esac
done