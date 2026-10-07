#!/bin/bash

echo "Waiting for boot completion..."
timeout 300 bash -c 'until adb shell getprop sys.boot_completed 2>/dev/null | grep -q "1"; do sleep 5; done' || echo "Boot completion timeout, continuing"

echo "Waiting for package manager..."
timeout 60 bash -c 'until adb shell pm list packages 2>/dev/null >/dev/null; do sleep 2; done' || echo "Package manager timeout, continuing"

echo "Waiting for settings service..."
timeout 60 bash -c 'until adb shell settings get global window_animation_scale 2>/dev/null >/dev/null; do sleep 2; done' || echo "Settings service timeout, continuing"

echo "Emulator readiness check completed"
