#!/bin/bash
set -x -e

# Pin the SDK to the project's fvm version (.fvmrc) — a bare `flutter` may
# resolve to a different fvm default and resolve deps with the wrong SDK.
_FLUTTER_VER=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)
if [ -n "$_FLUTTER_VER" ] && [ -d "$HOME/fvm/versions/$_FLUTTER_VER" ]; then
    export PATH="$HOME/fvm/versions/$_FLUTTER_VER/bin:$PATH"
fi

pids=()

# build_runner shells out to `dart compile`, which refuses to compile the build
# script when any dependency ships a `hook/build.dart` (a native build hook),
# directing to `dart build` instead. The Flutter 3.41.9 upgrade pulled in
# several such packages (payjoin, objective_c, sqlite3). Codegen runs only
# mobx_codegen/source_gen builders and never touches native code, so we
# temporarily hide every hook file in the pub caches and restore them on exit.
# The app build (`flutter run`/`build`) still processes the hooks normally.
#
# `pub get` (re)extracts packages and would recreate hook files we hid, so all
# pub gets must finish BEFORE the hooks are hidden. Jobs are chained with `&&`
# so a failed build_runner actually fails the job (a trailing `cd ..` used to
# swallow the exit code).
_COINS=(cw_core cw_evm cw_monero cw_bitcoin cw_nano cw_bitcoin_cash cw_solana cw_tron cw_wownero cw_zano cw_decred cw_dogecoin cw_zcash)

for cwcoin in "${_COINS[@]}"; do
    if [[ "x$1" == "xasync" ]]; then
        env PUB_CACHE=$HOME/.cache/pub-cache-$cwcoin bash -c "cd $cwcoin && flutter pub get" &
        pids+=($!)
    else
        (cd "$cwcoin" && flutter pub get)
    fi
done
# cw_mweb only resolves deps, no build_runner.
if [[ "x$1" == "xasync" ]]; then
    (cd cw_mweb && flutter pub get) &
    pids+=($!)
else
    (cd cw_mweb && flutter pub get)
fi
flutter pub get
if [[ "x$1" == "xasync" ]]; then
    for pid in "${pids[@]}"; do
        wait "$pid" || { echo "Error: pub get failed for pid $pid"; exit 1; }
    done
    pids=()
fi

# Async mode gives each coin its own PUB_CACHE (~/.cache/pub-cache-<coin>),
# and git deps land in <cache>/git rather than <cache>/hosted/pub.dev — hide
# hooks in every cache root, not just the default one.
_PUB_CACHES=("$HOME/.pub-cache" "$HOME"/.cache/pub-cache-cw_*)
_HIDDEN_HOOKS=()
shopt -s nullglob
# Self-heal: a previous run killed by SIGKILL leaves hooks __disabled__, which
# breaks `flutter run`/`build` (payjoin FFI symbol errors). Restore leftovers
# before hiding again.
for cache in "${_PUB_CACHES[@]}"; do
    # Git deps of monorepos (dart-lang/native, i18n) nest hooks in <pkg>/pkgs/*/
    # alongside top-level checkout hooks — both layouts must be covered.
    for f in "$cache"/hosted/pub.dev/*/hook/build.dart.__disabled__ \
             "$cache"/git/*/hook/build.dart.__disabled__ \
             "$cache"/git/*/pkgs/*/hook/build.dart.__disabled__; do
        mv "$f" "${f%.__disabled__}"
    done
    for f in "$cache"/hosted/pub.dev/*/hook/build.dart \
             "$cache"/git/*/hook/build.dart \
             "$cache"/git/*/pkgs/*/hook/build.dart; do
        mv "$f" "$f.__disabled__"
        _HIDDEN_HOOKS+=("$f")
    done
done
shopt -u nullglob
_restore_hooks() {
    # Ensure background coin builds have finished before restoring, so a slow
    # job is never left seeing a restored hook mid-compile (also covers the
    # `set -e` early-exit path).
    wait 2>/dev/null || true
    for f in "${_HIDDEN_HOOKS[@]}"; do
        [ -f "$f.__disabled__" ] && mv "$f.__disabled__" "$f"
    done
}
trap _restore_hooks EXIT
# EXIT trap does not fire on SIGKILL, and without trapping these signals the
# hook files stay __disabled__ if the script is interrupted mid-run.
trap _restore_hooks INT TERM HUP

for cwcoin in "${_COINS[@]}"; do
    if [[ "x$1" == "xasync" ]]; then
        env PUB_CACHE=$HOME/.cache/pub-cache-$cwcoin bash -c "cd $cwcoin && dart run build_runner build --delete-conflicting-outputs" &
        pids+=($!)
    else
        (cd "$cwcoin" && dart run build_runner build --delete-conflicting-outputs)
    fi
done
dart run build_runner build --delete-conflicting-outputs

for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        ec=$?
        echo "Error: Failed to generate models: $ec"
        exit $ec
    fi
done
