#!/bin/bash
set -x -e

pids=()

# build_runner shells out to `dart compile`, which refuses to compile the build
# script when any dependency ships a `hook/build.dart` (a native build hook),
# directing to `dart build` instead. The Flutter 3.41.9 upgrade pulled in
# several such packages (payjoin, objective_c, sqlite3). Codegen runs only
# mobx_codegen/source_gen builders and never touches native code, so we
# temporarily hide every hook file in the pub cache and restore them on exit.
# The app build (`flutter run`/`build`) still processes the hooks normally.
_HIDDEN_HOOKS=()
shopt -s nullglob
# Self-heal: a previous run killed by SIGKILL leaves hooks __disabled__, which
# breaks `flutter run`/`build` (payjoin FFI symbol errors). Restore leftovers
# before hiding again.
for f in "$HOME"/.pub-cache/hosted/pub.dev/*/hook/build.dart.__disabled__; do
    mv "$f" "${f%.__disabled__}"
done
for f in "$HOME"/.pub-cache/hosted/pub.dev/*/hook/build.dart; do
    mv "$f" "$f.__disabled__"
    _HIDDEN_HOOKS+=("$f")
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

for cwcoin in cw_{core,evm,monero,bitcoin,nano,bitcoin_cash,solana,tron,wownero,zano,decred,dogecoin,zcash}
do
    if [[ "x$1" == "xasync" ]];
    then
        env PUB_CACHE=$HOME/.cache/pub-cache-$cwcoin bash -c "cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd .." &
        pids+=($!)
    else
        cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
    fi
done
for cwcoin in cw_mweb;
do
    if [[ "x$1" == "xasync" ]];
    then
        bash -c "cd $cwcoin; flutter pub get; cd .." &
        pids+=($!)
    else
        cd $cwcoin; flutter pub get; cd ..
    fi
done

for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        ec=$?
        echo "Error: Failed to generate models: $ec"
        exit $ec
    fi
done

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter pub get

# In async mode the per-coin builds run as background jobs; wait for them all
# (and the root build above) to finish before the EXIT trap restores the hook
# files. Without this, the trap can fire while a slow coin (e.g. cw_bitcoin,
# which pulls in payjoin) is still mid-compile and the restored hook breaks it.
if [[ "x$1" == "xasync" ]]; then
    wait
fi
