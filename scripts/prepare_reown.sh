#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/functions.sh"
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

# this abomination of seds is needed because the version of reown we use has old dependencies that fail to properly run the codegen on 3.41
# should we ever upgrade reown this won't be needed


for pkg in reown_appkit reown_cli reown_core reown_sign reown_walletkit reown_yttrium; do
    universal_sed '
s|^  freezed: \^2\.5\.7$|  freezed: ^2.5.8|
s|^  dependency_validator: \^4\.1\.2$|  dependency_validator: ^5.1.0|
' "packages/$pkg/pubspec.yaml"
done

# mockito ^5.4.4 resolves to 5.4.5, whose builder.dart uses analyzer's private
# *Impl types removed in analyzer 7.x ("InterfaceElement can't be assigned to
# InterfaceElementImpl"). Bump to ^5.4.6 (raised analyzer min to >=7.4.1,
# source rewritten for public API). Stop at 5.4.6 — 5.5.0+ requires build
# ^3.0.0 which conflicts with freezed 2.x. Dev-only; not shipped in the .aar.
for pkg in reown_appkit reown_core reown_sign reown_walletkit; do
    universal_sed 's|^  mockito: \^5\.4\.4$|  mockito: ^5.4.6|' "packages/$pkg/pubspec.yaml"
done

# disables codegen/resolving for the examples. i really could not care less about them
for gen in packages/reown_appkit/generate_files.sh packages/reown_walletkit/generate_files.sh; do
  universal_sed '
1,/^cd example/ s|^flutter pub get$|flutter pub get --no-example|
/^cd example/,$ {
  s|^flutter clean$|#flutter clean|
  s|^flutter pub get$|#flutter pub get|
  s|^dart run build_runner build --delete-conflicting-outputs$|#dart run build_runner build --delete-conflicting-outputs|
  s|^cd ios$|#cd ios|
  s|^rm Podfile\.lock$|#rm Podfile.lock|
  /^pod install$/ { s|^|#|; n; s|^cd \.\.$|#cd ..|; }
}
' "$gen"
done
./scripts/generate_all.sh