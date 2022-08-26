#!/bin/sh

. ./config.sh
printf $(git log -1 --pretty=format:"%h %ad") >> build/git_commit_version.txt
cd build
cmake ../cmakefiles/${TYPES_OF_BUILD}
make -j$(nproc)


