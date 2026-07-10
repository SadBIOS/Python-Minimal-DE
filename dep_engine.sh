#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resolve--online)
            f
            ;;

        --resolve-offline)
            <function?> "$2"
            shift 2
            ;;

    esac
done
