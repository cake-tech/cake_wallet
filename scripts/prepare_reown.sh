#!/bin/bash
set -x -e
cd "$(dirname "$0")"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/functions.sh"

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

universal_sed '
s|^  freezed_annotation: \^2\.4\.4$|  freezed_annotation: ^3.1.0|
s|^  dependency_validator: \^4\.1\.2$|  dependency_validator: ^5.1.0|
s|^  freezed: \^2\.5\.7$|  freezed: ^3.1.0|
s|^  mockito: \^5\.4\.4$|  mockito: ^5.6.4|
' packages/reown_appkit/pubspec.yaml

universal_sed '
s|^  sdk: ">=3\.2\.3 <4\.0\.0"$|  sdk: ">=3.10.0 <4.0.0"|
s|^  freezed_annotation: \^2\.4\.4$|  freezed_annotation: ^3.1.0|
s|^  dependency_validator: \^4\.1\.2$|  dependency_validator: ^5.1.0|
s|^  freezed: \^2\.5\.7$|  freezed: ^3.2.5|
s|^  mockito: \^5\.4\.4$|  mockito: ^5.6.4|
' packages/reown_core/pubspec.yaml

universal_sed '
s|^  sdk: ">=3\.2\.3 <4\.0\.0"$|  sdk: ">=3.10.0 <4.0.0"|
s|^  freezed_annotation: \^2\.4\.4$|  freezed_annotation: ^3.1.0|
s|^  dependency_validator: \^4\.1\.2$|  dependency_validator: ^5.1.0|
s|^  freezed: \^2\.5\.7$|  freezed: ^3.2.5|
' packages/reown_sign/pubspec.yaml

universal_sed '
s|^  sdk: ">=3\.2\.3 <4\.0\.0"$|  sdk: ">=3.10.0 <4.0.0"|
s|^  dependency_validator: \^4\.1\.2$|  dependency_validator: ^5.1.0|
s|^  mockito: \^5\.4\.4$|  mockito: ^5.6.4|
' packages/reown_walletkit/pubspec.yaml

universal_sed '
s|^  sdk: \^3\.5\.4$|  sdk: ^3.10.0|
s|^  freezed_annotation: \^2\.4\.4$|  freezed_annotation: ^3.1.0|
s|^  dependency_validator: \^4\.1\.2$|  dependency_validator: ^5.1.0|
s|^  freezed: \^2\.5\.7$|  freezed: ^3.2.5|
' packages/reown_yttrium/pubspec.yaml

grep -q '^  mockito:' packages/reown_yttrium/pubspec.yaml || universal_sed '
/^  json_serializable: \^6\.9\.0$/a\
  mockito: ^5.6.4
' packages/reown_yttrium/pubspec.yaml

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