#!/bin/bash
set -x -e
cd $(dirname $0)
cd ..

dart fix --apply .
dart format --line-length=100 .
if [[ ! "x$ABORT_ON_CHANGE" == "x" ]]; then
  if [[ ! -z "$(git status --porcelain -- $(find .))" ]]; then
    echo "Please run scripts/lint.sh"
    exit 1
  fi
fi
