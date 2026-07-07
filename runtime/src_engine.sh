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


PY_VER=""
OVER_WRITE_ARCHIVE=0
MISS=0
FAIL=0
PASS=0
SIZE=""

function download_links() {
    wget -v -O "$HTML_SOURCE" https://www.python.org/downloads/source/

    grep -oE "(https?://www\.python\.org)?/ftp/python/[^\"'\s>]+/Python-[^\"'\s>]+" "$HTML_SOURCE" | grep -vE '[0-9](a|b|rc)[0-9]' | sed -E 's|^(https?://www\.python\.org)?|https://www.python.org|' | awk -F'/' '{score=0; if($0~/\.tar\.xz$/)score=3; else if($0~/\.tar\.bz2$/)score=2; else if($0~/\.tgz$/||$0~/\.tar\.gz$/)score=1; if(!($6 in b) || score>b[$6]){b[$6]=score; u[$6]=$0}} END{for(v in u) print u[v]}' | sort -V > "$OUTPUT_FILE"
    echo "Partial/broken cache has been rebuilt"
    exit 0
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
            exit 0
        else
            echo "Operation cancelled by user"
            exit 0
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

# function update_archive() {}

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

            elif [[ -f "$HTML_SOURCE" && -f "$OUTPUT_FILE" ]]; then
                echo "Cache exists. If you rebuild, use 'make force_cache_rebuild'"
                exit 0
            fi
        ;;

        --force-build-cache)
            if [[ -f "$HTML_SOURCE" && -f "$OUTPUT_FILE" ]]; then
                download_links
            fi
        ;;

        --download-all)
            verify_archive
            if [[ $MISS -gt 0 || $FAIL -gt 0 ]]; then
                printf "\nPlease check \e[33m$ERR_DMP_FILE\e[0m before proceeding\n"
                build_archive
            
            else
                printf "All files have been checked to be \e[32mGOOD\e[0m\n"
            fi
            exit 0
        ;;

        --download-exact)
        exit 0
        ;;
        --download-best)
        exit 0
        ;;
        --download-max-support)
        exit 0
        ;;
        --download-bleeding)
        exit 0
        ;;
        --verify-archive)
        verify_archive
        echo "Total files in archive : $(find "$SRC_CMP_DIR" -type f | wc -l)"
        printf "\n\e[32mPassed\e[0m  : $PASS/$(wc -l $SRC_CMP_CHKSUM | awk '{print $1}')\n"
        printf "\e[33mMissing\e[0m : $MISS/$(wc -l $SRC_CMP_CHKSUM | awk '{print $1}')\n"
        printf "\e[31mFailed\e[0m  : $FAIL/$(wc -l $SRC_CMP_CHKSUM | awk '{print $1}')\n"
        printf "\e[36mSize\e[0m    : $SIZE/$(df -h / | awk 'NR==2 {print $4}')\n"
        exit 0
        ;;
        --wipe-archive)
        exit 0
        ;;
        --update-archive)
        exit 0
        ;;
    esac
done