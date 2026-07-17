#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_CMP_DIR="$SCRIPT_ROOT/data/src_root/archives"
BUILD_DIR="$SCRIPT_ROOT/data/build_dir"
SRC_ALIAS="$SCRIPT_ROOT/data/build_dir/Python-"
BIN_ROOT="$SCRIPT_ROOT/data/build_dir/compiled_binaries"
BIN_PATHS="$SCRIPT_ROOT/data/build_dir/bin_paths.txt"
ENGINE_SCRIPT="$SCRIPT_ROOT/dep_engine.sh"


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
        echo "No source archive found for python $py_branch"
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

function extract_exact() {
    py_version="$1"

    mkdir -p "$BUILD_DIR"

    archive=""
    for ext in tar.xz tar.bz2 tar.gz tgz; do
        if [[ -f "$SRC_CMP_DIR/Python-${py_version}.${ext}" ]]; then
            archive="$SRC_CMP_DIR/Python-${py_version}.${ext}"
            break
        fi
    done

    if [[ -z "$archive" ]]; then
        echo "Error: source archive for Python ${py_version} not found."
        return 1
    fi

    filename=$(basename "$archive")

    exact_version="${filename#Python-}"
    exact_version="${exact_version%.tar.xz}"
    exact_version="${exact_version%.tar.bz2}"
    exact_version="${exact_version%.tar.gz}"
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
    if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
        rm -vrf "$BUILD_DIR"/Python-[0-9]*
    fi
}

function clean_bins() {
    if [[ -n "$BIN_ROOT" && -d "$BIN_ROOT" ]]; then
        rm -vrf "$BIN_ROOT"/py_bin_*
    fi
}

function pybuild() {
    search_version="$1"

    match_line=$(awk -F'<[|]>' -v ver="^${search_version}" '$2 ~ ver {print $0}' "$BIN_PATHS" | sort -V | tail -n 1)

    latest_version=$(awk -F'<[|]>' '{print $2}' <<< "$match_line")
    bin_path=$(awk -F'<[|]>' '{print $3}' <<< "$match_line")

    src_path="${SRC_ALIAS}${latest_version}"

    cd "${src_path}"

    ./configure --prefix="${bin_path}" --enable-optimizations --with-ensurepip=install
    
    make -j "$(nproc)"
    make install

    cd "$SCRIPT_ROOT"
}

function pybuild_specific() {
    exact_version="$1"

    match_line=$(awk -F'<[|]>' -v ver="$exact_version" '$2 == ver {print $0}' "$BIN_PATHS")

    if [[ -z "$match_line" ]]; then
        echo "Error: build information for Python $exact_version not found."
        return 1
    fi

    version=$(awk -F'<[|]>' '{print $2}' <<< "$match_line")
    bin_path=$(awk -F'<[|]>' '{print $3}' <<< "$match_line")

    src_path="${SRC_ALIAS}${version}"

    cd "$src_path" || return 1

    ./configure --prefix="${bin_path}" --enable-optimizations --with-ensurepip=install

    make -j"$(nproc)"
    make install

    cd "$SCRIPT_ROOT"
}

function builder() {
    build_var="$1"

    deps=(
        build-essential
        pkg-config
        libssl-dev
        zlib1g-dev
        libncurses-dev
        libreadline-dev
        libsqlite3-dev
        libgdbm-dev
        libbz2-dev
        libexpat1-dev
        liblzma-dev
        tk-dev
        libffi-dev
        uuid-dev
    )

    missing=()

    for pkg in "${deps[@]}"; do
        if ! dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null | grep -q "^install ok installed$"; then
            missing+=("$pkg")
        fi
    done

    if ((${#missing[@]} == 0)); then

        if [[ "$build_var" =~ ^[0-9]+\.[0-9]+$ ]]; then
            extractor "$build_var"
            pybuild "$build_var"

        elif [[ "$build_var" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            extract_exact "$build_var"
            pybuild_specific "$build_var"
        fi

        clean_cache
        exit 0
    fi

    echo "Missing packages:"
    printf '\e[31m%s\e[0m\n' "${missing[@]}"
    echo
    echo "To resolve dependency issues please select one of the following options:"
    echo "  1. Online"
    echo "  2. From local archive"

    read -rp "Type the option number only: " option

    case "$option" in
        1)
            bash "$ENGINE_SCRIPT" --resolve-online
        ;;
        
        2)
            bash "$ENGINE_SCRIPT" --resolve-offline
        ;;
    
    esac
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        --build)
            builder "$2"
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

        --build-exact)
            builder "$2"
            exit 0
        ;;

    esac
done