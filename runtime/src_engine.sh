#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HTML_SOURCE="$SCRIPT_ROOT/data/src_root/source.html"
OUTPUT_FILE="$SCRIPT_ROOT/data/src_root/scr_url_list.txt"
SRC_CMP_DIR="$SCRIPT_ROOT/data/src_root/archives"
SRC_CMP_CHKSUM="$SCRIPT_ROOT/data/src_root/src_chksum_sha512.txt"
ERR_DMP_FILE="$SCRIPT_ROOT/data/src_root/check_fail.txt"
SRC_UPDT_LOG="$SCRIPT_ROOT/data/src_root/src_update.txt"

mkdir -pv "$SCRIPT_ROOT/data/src_root/archives"
touch "$HTML_SOURCE" "$OUTPUT_FILE" "$SRC_CMP_CHKSUM" "$ERR_DMP_FILE" "$SRC_UPDT_LOG"

OVER_WRITE_ARCHIVE=0
MISS=0
FAIL=0
PASS=0
SIZE=""

function download_links() {
    wget -v -O "$HTML_SOURCE" https://www.python.org/downloads/source/

    grep -oE "(https?://www\.python\.org)?/ftp/python/[^\"'\s>]+/Python-[^\"'\s>]+" "$HTML_SOURCE" | grep -vE '[0-9](a|b|rc)[0-9]' | sed -E 's|^(https?://www\.python\.org)?|https://www.python.org|' | awk -F'/' '{score=0; if($0~/\.tar\.xz$/)score=3; else if($0~/\.tar\.bz2$/)score=2; else if($0~/\.tgz$/||$0~/\.tar\.gz$/)score=1; if(!($6 in b) || score>b[$6]){b[$6]=score; u[$6]=$0}} END{for(v in u) print u[v]}' | sort -V > "$OUTPUT_FILE"
}

function build_archive() {
    printf "This will consume \e[31mMULTIPLE GIGABYTES\e[0m of storage when completed\n"
    read -r -p "Type YES to continue: " reply
        if [[ "$reply" == "YES" ]]; then
            while IFS= read -r url; do
                [[ -z "$url" ]] && continue

                filename="$(basename "$url")"
                filepath="$SRC_CMP_DIR/$filename"

                wget -v -O "$filepath" "$url"

                if [[ ! -f "$filepath" ]]; then
                    echo "Failed to download $url" >&2
                    continue
                fi

                sha512sum_value="$(sha512sum "$filepath" | awk '{print $1}')"

                echo "<|> $filename <|> $sha512sum_value <|>" >> "$SRC_CMP_CHKSUM"

            done < "$OUTPUT_FILE"
        else
            echo "Operation cancelled by user"
        fi
}

function verify_archive() {
    truncate -s 0 "$ERR_DMP_FILE"

    while IFS='|' read -r filename expected_hash; do
        filepath="$SRC_CMP_DIR/$filename"

        if [[ ! -f "$filepath" ]]; then
            printf "FILE: %s\nEXPECTED: %s\nACTUAL: MISSING\n\n" "$filename" "$expected_hash" >> "$ERR_DMP_FILE"
            ((MISS++))
            continue
        fi

        actual_hash=$(sha512sum "$filepath" | awk '{print $1}')

        if [[ "$actual_hash" == "$expected_hash" ]]; then
            ((PASS++))
        else
            printf "FILE: %s\nEXPECTED: %s\nACTUAL: %s\n\n" "$filename" "$expected_hash" "$actual_hash" >> "$ERR_DMP_FILE"
            ((FAIL++))
        fi
    done < <(sed -n -E 's/^<\|>[[:space:]]*([^[:space:]][^|]*[^[:space:]])[[:space:]]*<\|>[[:space:]]*([0-9a-fA-F]{128})[[:space:]]*<\|>$/\1|\2/p' "$SRC_CMP_CHKSUM")

    SIZE=$(du -sh "$SRC_CMP_DIR" | awk '{print $1}')
}

function update_archive() {
    download_links

    latest_local=$(find "$SRC_CMP_DIR" -maxdepth 1 -type f -name "Python-*" | grep -oE 'Python-[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/Python-//' | sort -V | tail -n 1)

    [[ -z "$latest_local" ]] && latest_local="0.0.0"

    updated_files=0

    while IFS= read -r url; do
        [[ -z "$url" ]] && continue

        filename="$(basename "$url")"
        filepath="$SRC_CMP_DIR/$filename"

        [[ -f "$filepath" ]] && continue

        file_version=$(echo "$filename" | grep -oE 'Python-[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/Python-//')

        older_ver=$(printf '%s\n%s' "$latest_local" "$file_version" | sort -V | head -n 1)

        if [[ "$older_ver" == "$file_version" && "$file_version" != "$latest_local" ]]; then
            echo "Skipping $filename (Version $file_version is older than latest local $latest_local) - nothing has been updated."
            continue
        fi

        echo "Downloading missing/new archive: $filename..."
        wget -v -O "$filepath" "$url"

        if [[ ! -f "$filepath" ]]; then
            echo "Error: Failed to download $url" >&2
            continue
        fi

        sha512sum_value="$(sha512sum "$filepath" | awk '{print $1}')"

        {
            echo "DATE: $(date "+%Y-%m-%d %H:%M:%S")"
            echo "FILE_NAME: $filename"
            echo "SHA512HASH: $sha512sum_value"
            echo ""
        } >> "$SRC_UPDT_LOG"

        ((updated_files++))

    done < "$OUTPUT_FILE"

    if [[ $updated_files -gt 0 ]]; then
        echo "Updates found. Rebuilding the entire checksum file..."
        truncate -s 0 "$SRC_CMP_CHKSUM"

        find "$SRC_CMP_DIR" -maxdepth 1 -type f -name "Python-*" -exec basename {} \; | \
            sort -V | \
            while read -r arch; do
                fpath="$SRC_CMP_DIR/$arch"
                h_val=$(sha512sum "$fpath" | awk '{print $1}')
                echo "<|> $arch <|> $h_val <|>" >> "$SRC_CMP_CHKSUM"
            done

        echo "Update complete: Successfully downloaded $updated_files new file(s) and rebuilt checksums."
    else
        echo "Check complete: No new updates were found or downloaded."
    fi
}

function download_specific() {

    url=$(grep "/Python-$1\.\(tar\.xz\|tar\.bz2\|tgz\|tar\.gz\)$" "$OUTPUT_FILE")

    [[ -z "$url" ]] && {
        echo "Version $1 not found"
        return
    }

    filename=$(basename "$url")

    [[ -f "$SRC_CMP_DIR/$filename" ]] && {
        echo "$1 version already exists"
        return
    }

    wget -v -O "$SRC_CMP_DIR/$filename" "$url"

    [[ ! -f "$SRC_CMP_DIR/$filename" ]] && {
        echo "Failed to download $filename"
        return
    }

    truncate -s 0 "$SRC_CMP_CHKSUM"

    find "$SRC_CMP_DIR" -maxdepth 1 -type f -name "Python-*" -exec basename {} \; |
        sort -V |
        while read -r arch; do
            echo "<|> $arch <|> $(sha512sum "$SRC_CMP_DIR/$arch" | awk '{print $1}') <|>"
        done > "$SRC_CMP_CHKSUM"
}

function download_x_latest() {
    if [[ -n "$1" ]]; then
        url=$(grep -E "/Python-$1\.[0-9]+\.(tar\.xz|tar\.bz2|tgz|tar\.gz)$" "$OUTPUT_FILE" | sort -V | tail -n 1)
    else
        url=$(sort -V "$OUTPUT_FILE" | tail -n 1)
    fi

    [[ -z "$url" ]] && {
        echo "No matching version found"
        return
    }

    filename=$(basename "$url")

    [[ -f "$SRC_CMP_DIR/$filename" ]] && {
        echo "$filename already exists"
        return
    }

    wget -v -O "$SRC_CMP_DIR/$filename" "$url"

    [[ ! -f "$SRC_CMP_DIR/$filename" ]] && {
        echo "Failed to download $filename"
        return
    }

    truncate -s 0 "$SRC_CMP_CHKSUM"

    find "$SRC_CMP_DIR" -maxdepth 1 -type f -name "Python-*" -exec basename {} \; |
        sort -V |
        while read -r arch; do
            echo "<|> $arch <|> $(sha512sum "$SRC_CMP_DIR/$arch" | awk '{print $1}') <|>"
        done > "$SRC_CMP_CHKSUM"
}

function regen_checksum() {
    truncate -s 0 "$SRC_CMP_CHKSUM"

    find "$SRC_CMP_DIR" -maxdepth 1 -type f -name "Python-*" -exec basename {} \; |
        sort -V |
        while read -r arch; do
            echo "<|> $arch <|> $(sha512sum "$SRC_CMP_DIR/$arch" | awk '{print $1}') <|>"
        done > "$SRC_CMP_CHKSUM"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --wipe-cache)
            if [[ -f "$HTML_SOURCE" && -f "$OUTPUT_FILE" ]]; then
                echo "Cache already exists. If you want to force wipe, use 'make force_cache_wipe'"
                exit 0
            elif [[ ! -f "$HTML_SOURCE" && ! -f "$OUTPUT_FILE" ]]; then
                echo "Nothing to wipe"
                exit 0
            elif [[ ! -f "$HTML_SOURCE" || ! -f "$OUTPUT_FILE" ]]; then
                rm -vrf "$HTML_SOURCE" "$OUTPUT_FILE"
                echo "Partial/broken cache has been wiped"
                exit 0
            fi
        ;;

        --force-wipe-cache)
            if [[ -f "$HTML_SOURCE" && -f "$OUTPUT_FILE" ]]; then
                rm -vrf "$HTML_SOURCE" "$OUTPUT_FILE"
                echo "Cache has been forcefully wiped"
                exit 0
            else
                echo "Nothing to wipe"
                exit 0
            fi
        ;;

        --build-cache)
            if [[ ! -f "$HTML_SOURCE" || ! -f "$OUTPUT_FILE" ]]; then
                download_links
                echo "Partial/broken cache has been rebuilt"
                exit 0
            elif [[ -f "$HTML_SOURCE" && -f "$OUTPUT_FILE" ]]; then
                echo "Cache exists. If you rebuild, use 'make force_cache_rebuild'"
                exit 0
            fi
        ;;

        --force-build-cache)
            if [[ -f "$HTML_SOURCE" && -f "$OUTPUT_FILE" ]]; then
                download_links
                echo "Cache has been forcefully rebuilt"
                exit 0
            fi
        ;;

        --download-all)
            verify_archive
            if [[ $MISS -gt 0 || $FAIL -gt 0 ]]; then
                printf "\nPlease check \e[33m$ERR_DMP_FILE\e[0m before proceeding\n"
                build_archive
                exit 0
            else
                printf "All files have been checked to be \e[32mGOOD\e[0m\n"
            fi
            exit 0
        ;;

        --force-download-all)
            build_archive
            exit 0
        ;;

        --download-exact)
            download_specific "$2"
            exit 0
        ;;

        --download-max-patch-lvl)
            download_x_latest "$2"
            exit 0
        ;;

        --download-bleeding)
            download_x_latest
            exit 0
        ;;

        --verify-archive)
            regen_checksum
            verify_archive
            printf "%-22s : %s\n" "Total files in archive" "$(find "$SRC_CMP_DIR" -type f | wc -l)"
            printf "\e[32m%-22s\e[0m : %s/%s\n" "Passed" "$PASS" "$(wc -l < "$SRC_CMP_CHKSUM")"
            printf "\e[33m%-22s\e[0m : %s/%s\n" "Missing" "$MISS" "$(wc -l < "$SRC_CMP_CHKSUM")"
            printf "\e[31m%-22s\e[0m : %s/%s\n" "Failed" "$FAIL" "$(wc -l < "$SRC_CMP_CHKSUM")"
            printf "\e[36m%-22s\e[0m : %s/%s\n" "Size" "$SIZE" "$(df -h / | awk 'NR==2 {print $4}')"
            exit 0
        ;;

        --wipe-archive)
            printf "You are about to  \e[31mWIPE MULTIPLE GIGABYTES\e[0m of data\n"
            read -r -p "Type YES to continue: " reply
                if [[ "$reply" == "YES" ]]; then
                    rm -vrf "$SRC_CMP_DIR"/*
                else
                    echo "Operation cancelled by user"
                fi
            exit 0
        ;;

        --update-archive)
            update_archive
            exit 0
        ;;
        
    esac
done