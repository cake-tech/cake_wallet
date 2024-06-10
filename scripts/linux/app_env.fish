#!/usr/bin/env fish

set -g APP_LINUX_NAME ""
set -g APP_LINUX_VERSION ""
set -g APP_LINUX_BUILD_NUMBER ""

set -g CAKEWALLET "cakewallet"

set -g TYPES $CAKEWALLET
set -g APP_LINUX_TYPE $CAKEWALLET

if test -n "$argv[1]"
    set -g APP_LINUX_TYPE $argv[1]
end

set -g CAKEWALLET_NAME "Cake Wallet"
set -g CAKEWALLET_VERSION "1.9.0"
set -g CAKEWALLET_BUILD_NUMBER 29

if not contains -- $APP_LINUX_TYPE $TYPES
    echo "Wrong app type."
    exit 1
end

switch $APP_LINUX_TYPE
    case $CAKEWALLET
        set -g APP_LINUX_NAME $CAKEWALLET_NAME
        set -g APP_LINUX_VERSION $CAKEWALLET_VERSION
        set -g APP_LINUX_BUILD_NUMBER $CAKEWALLET_BUILD_NUMBER
end

export APP_LINUX_TYPE
export APP_LINUX_NAME
export APP_LINUX_VERSION
export APP_LINUX_BUILD_NUMBER
