#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

sudo -v || {
    printf "\n\e[31mAuthentication failed\e[0m\n" >&2
    exit 1
}

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DEPS=(
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

function conn_stat() {
    ping -c 1 -W 2 1.1.1.1 &>/dev/null || ping -c 1 -W 2 8.8.8.8 &>/dev/null
}

function online() {
    if ! conn_stat; then
        echo "Cannot resolve dependencies on an offline machine" >&2
        exit 1
    fi

    sudo apt update && sudo apt install -y "${DEPS[@]}"
}

function makepkg_cache() {
    if conn_stat; then
        read -rp "Machine is online. Force build offline dependency archive? (y/n): " choice
        case "$choice" in
            [yY][eE][sS]|[yY])
                sudo apt clean
                sudo apt update
                sudo apt-get install --download-only --reinstall -y "${DEPS[@]}"
                target_dir="$SCRIPT_ROOT/py_build_dependencies"
                mkdir -p "$target_dir"
                sudo cp -v /var/cache/apt/archives/*.deb "$target_dir/"
                sudo chown -Rv "$USER:$USER" "$target_dir"
                cd "$SCRIPT_ROOT"
                tar -czvf py_build_dependencies.tar.gz py_build_dependencies
                rm -vrf dirpath="$SCRIPT_ROOT/py_build_dependencies"
                echo "Offline archive successfully created at: $SCRIPT_ROOT/py_build_dependencies.tar.gz"
                exit 0
                ;;
        esac
    else
        echo "Machine is offline. Cannot build dependency archive" >&2
        exit 1
    fi

}

function offline() {
    archive="${1:-$SCRIPT_ROOT/py_build_dependencies.tar.gz}"

    if [[ ! -f "$archive" ]]; then
        echo "Archive '$archive' does not exist" >&2
        read -p "Build archive now? (y/n): " optn
        case "$optn" in
            y|Y|yes|YES)
                makepkg_cache
                exit 0
                ;;
            n|N|no|NO)
                exit 0
                ;;
        esac
    fi

    tar -xzvf "$archive" -C "$SCRIPT_ROOT"

    dirpath="$SCRIPT_ROOT/py_build_dependencies"

    if [[ -f /etc/apt/sources.list ]]; then
        sudo mv -v /etc/apt/sources.list /etc/apt/sources.list.bak
        trap 'echo "Restoring APT mirrors..."; [ -f /etc/apt/sources.list.bak ] && sudo mv -v /etc/apt/sources.list.bak /etc/apt/sources.list' EXIT
    fi

    sudo apt install -y "$dirpath"/*.deb
    rm -vrf dirpath="$SCRIPT_ROOT/py_build_dependencies"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resolve-online)
            online
            exit 0
            ;;

        --resolve-offline)
            offline "$2"
            shift 2
            exit 0
            ;;

        --build-offline)
            makepkg_cache
            exit 0
            ;;

    esac
done