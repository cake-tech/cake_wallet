#!/bin/bash

SIMPLYBS_HASH=0c18626f142df1f0945bb0ca6147d39829a77374
SIMPLYBS_URL="https://github.com/mrcyjanex/simplybs_private"

if [[ "x$SIMPLYBS_TOKEN" == "x" ]]; then
    echo "SIMPLYBS_TOKEN is not set, it allows you to cache your builds in the cloud so you can download them later."
    echo "SIMPLYBS_TOKEN=xxxx should be added to ~/.zshrc or wherever you store your environment variables."
    echo "p.s. all of that is signed with your PGP key so it doesn't add unnecessary trust requirements."
fi

SIMPLYBS_DIR="$HOME/.local/share/simplybs/repo/"

if [[ ! -d "$SIMPLYBS_DIR/.git" ]]; then
    git clone "$SIMPLYBS_URL" "$SIMPLYBS_DIR"
fi

cd "$SIMPLYBS_DIR"
git fetch origin
git checkout "$SIMPLYBS_HASH"
git pull origin "$SIMPLYBS_HASH"