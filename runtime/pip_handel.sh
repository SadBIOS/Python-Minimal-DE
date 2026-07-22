#!/bin/bash

if [[ $# -eq 0 ]]; then
  exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"


function req_resolver() {}
function req_processor() {}
