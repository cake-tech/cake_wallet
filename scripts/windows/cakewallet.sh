#!/bin/bash
# This (wrapper) script should be run in wsl with installed (windows "side") flutter
# and available cmd.exe in PATH
# Assume that we are in scripts/windows dir
CW_ROOT=`pwd`/../..
cd $CW_ROOT
cmd.exe /c cakewallet.bat $1