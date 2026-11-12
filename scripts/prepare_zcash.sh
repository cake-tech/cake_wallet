#!/bin/bash
set -x -e
cd "$(dirname "$0")"

HASH=5800cfdfc89ae46d8a343721d052d5e02470c2a7

if [[ ! -d "zcash_lib/.git" ]];
then
    rm -rf zcash_lib
    git clone https://github.com/MrCyjaneK/zwallet.git zcash_lib
    cd zcash_lib
else
    cd zcash_lib
    git fetch -a
fi


git reset --hard
git checkout $HASH
git reset --hard
git submodule update --init --force --recursive

# in go I could nicely replace => the heck out of it
# sadly rust is not go
find . -name Cargo.toml -exec sed -i.bak -E '
s|rusqlite[[:space:]]*=[[:space:]]*\{[^}]*\}|rusqlite = { version = "0.29.0", features = ["bundled", "modern_sqlite", "backup"] }|g
' {} +
# find . -name Cargo.toml -exec sed -i.bak -E 's|r2d2_sqlite[[:space:]]*=[[:space:]]*([^\n]*)|r2d2_sqlite = "0.32.0"|g' {} +
