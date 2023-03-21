#!/bin/sh

. ./config.sh
cd IOS_SCRIPTS_DIR
./create_git_versions_file.sh
cd IOS_SCRIPTS_DIR
./setup_monero.sh
cd IOS_SCRIPTS_DIR
./setup_wownero.sh