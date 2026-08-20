#!/bin/bash
set -x -e

cd $(dirname $0)

source ../elinux/flutter-sfos.env


if ! command -v sfosbuild &>/dev/null;
then
    echo "sfosbuild not found!"
    echo "go install gtihub.com/mrcyjanek/sfosbuild@latest"
    exit 1
fi

FLUTTER_SFOS_HASH="1900bfd8785c00a7067a394528e8cc26b9ffcc87"

if [[ ! -d "sfos" ]];
then
    mkdir sfos
fi
cd sfos

if [[ ! -d "flutter-sailfishos/.git" ]];
then
    rm -rf flutter-sailfishos
    git clone https://github.com/mrcyjanek/flutter-sailfishos flutter-sailfishos
    cd flutter-sailfishos
else
    cd flutter-sailfishos
fi

git fetch -a
git checkout $FLUTTER_SFOS_HASH
git reset --hard

for SFOS_VERSION in 5.1.0.11;
do
    make engine SFOS=$SFOS_VERSION ARCH=aarch64 FLUTTER=$FLUTTER_VERSION
    make runtime SFOS=$SFOS_VERSION ARCH=aarch64 FLUTTER=$FLUTTER_VERSION
done