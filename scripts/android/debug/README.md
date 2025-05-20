# Debug scripts

## `display_fuzzer_stats.sh`

Displays wallet fuzzer statistics in one screen for every emulator

## `record_tap.sh`

Used to configure wallet_fuzzer.sh - to unlock wallet and start fuzzer (or any action we wish to test)

## `wallet_fuzzer.sh`

Main logic to start wallet fuzzing scripts

## Extras

In order to install app on all devices you can run the following command:

```bash
for device in $(adb devices | grep -w "device" | awk '{print $1}'); do
    echo "Installing on $device..."
    adb -s $device install -r build/app/outputs/flutter-apk/app-debug.apk
done
```

To watch for some log message:

```bash
for device in $(adb devices | grep -w "device" | awk '{print $1}'); do
    echo "Watching logs on $device..."
    adb -s "$device" logcat | grep --line-buffered "WalletInfo corrupted" | sed "s/^/[$device] /" &
done

wait
```