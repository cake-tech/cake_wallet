#!/bin/bash

detect_sed() {
    if sed --version 2>/dev/null | grep -q "GNU"; then
        SED_TYPE="GNU"
    else
        SED_TYPE="BSD"
    fi
}

universal_sed() {
    local expression=$1
    local file=$2

    if [[ "$SED_TYPE" == "GNU" ]]; then
        sed -i "$expression" "$file"
    else
        sed -i '' "$expression" "$file"
    fi
}

detect_sed
