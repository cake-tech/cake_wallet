#!/bin/bash
set -x -e
cd $(dirname $0)
cd ..

for i in cw_zcash;
do
    dart fix --apply $i/
    dart format --line-length=120 $i/
    if [[ ! "x$ABORT_ON_CHANGE" == "x" ]];
    then
        if [[ -z "$(git status --porcelain -- "$(find $i)")" ]];
        then
            echo "Please run scripts/lint.sh ($i has changes)"
            exit 1
        fi
    fi
done
