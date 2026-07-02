#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Reown` in
# - .github/workflows/pr_test_build_android.yml 
# - .github/workflows/pr_test_build_linux.yml
# https://github.com/cake-tech/reown_flutter/releases/download/v0.0.4/reown_flutter-v0.0.4.tar.gz

HASH=8a6d79ef7a268c493eeba45feef9991eea119bbd

if [[ ! -d "reown_flutter/.git" ]];
then
    rm -rf reown_flutter
    git clone https://github.com/cake-tech/reown_flutter
    cd reown_flutter
else
    cd reown_flutter
    git fetch -a
fi

git reset --hard
git checkout $HASH
git reset --hard

# Pinned commit predates current analyzer resolution; bump dev-only deps so pub
# can solve cleanly on current Flutter without forcing source-incompatible
# analyzer versions. None of these ship in the produced .aar.
#
# 1. dependency_validator ^4.1.2 caps analyzer <7.0.0, conflicting with
#    freezed 2.5.8+ (which allows analyzer 7.x). Bump to ^5.0.5.
# 2. mockito ^5.4.4 resolves to 5.4.5, whose builder.dart uses analyzer's
#    private *Impl types removed in analyzer 7.x ("InterfaceElement can't be
#    assigned to InterfaceElementImpl"). Bump to ^5.4.6 (raised analyzer
#    min to >=7.4.1, source rewritten for public API). Stop at 5.4.6 —
#    5.5.0+ requires build ^3.0.0 which conflicts with freezed 2.x.
for pkg in reown_appkit reown_cli reown_core reown_sign reown_walletkit reown_yttrium; do
  sed -i 's/dependency_validator: \^4.1.2/dependency_validator: ^5.0.5/' "packages/$pkg/pubspec.yaml"
done
for pkg in reown_appkit reown_core reown_sign reown_walletkit; do
  sed -i 's/mockito: \^5.4.4/mockito: ^5.4.6/' "packages/$pkg/pubspec.yaml"
done

./scripts/generate_all.sh