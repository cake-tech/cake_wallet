package com.cakewallet.cake_wallet;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import android.media.AudioManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;
import android.content.Intent;
import android.net.Uri;
import android.os.PowerManager;
import android.provider.Settings;

import java.security.SecureRandom;

public class MainActivity extends FlutterFragmentActivity {
    final String UTILS_CHANNEL = "com.cake_wallet/native_utils";
    final String PHONE_CALL_STATUS_CHANNEL = "com.cake_wallet/phone_call_status";
    boolean isAppSecure = false;
    @RequiresApi(api = Build.VERSION_CODES.S)
    private AudioManager.OnModeChangedListener audioModeListener;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel utilsChannel =
                new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                        UTILS_CHANNEL);

        utilsChannel.setMethodCallHandler(this::handle);

        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                PHONE_CALL_STATUS_CHANNEL).setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    audioModeListener = mode -> events.success(isCallMode(mode));
                    getAudioManager().addOnModeChangedListener(getMainExecutor(), audioModeListener);
                }
                events.success(isOnPhoneCall());
            }

            @Override
            public void onCancel(Object arguments) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && audioModeListener != null) {
                    getAudioManager().removeOnModeChangedListener(audioModeListener);
                    audioModeListener = null;
                }
            }
        });
    }

    private void handle(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        Handler handler = new Handler(Looper.getMainLooper());

        try {
            switch (call.method) {
                case "sec_random":
                    int count = call.argument("count");
                    SecureRandom random = new SecureRandom();
                    byte bytes[] = new byte[count];
                    random.nextBytes(bytes);
                    handler.post(() -> result.success(bytes));
                    break;
                case "setIsAppSecure":
                    isAppSecure = call.argument("isAppSecure");
                    if (isAppSecure) {
                        getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
                    } else {
                        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
                    }
                    break;
                case "disableBatteryOptimization":
                    disableBatteryOptimization();
                    handler.post(() -> result.success(null));
                    break;
                case "isBatteryOptimizationDisabled":
                    boolean isDisabled = isBatteryOptimizationDisabled();
                    handler.post(() -> result.success(isDisabled));
                    break;
                case "is_on_phone_call":
                    boolean isOnPhoneCall = isOnPhoneCall();
                    handler.post(() -> result.success(isOnPhoneCall));
                    break;
                default:
                    handler.post(() -> result.notImplemented());
            }
        } catch (Exception e) {
            handler.post(() -> result.error("UNCAUGHT_ERROR", e.getMessage(), null));
        }
    }

    private void disableBatteryOptimization() {
        String packageName = getPackageName();
        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
            Intent intent = new Intent();
            intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
            intent.setData(Uri.parse("package:" + packageName));
            startActivity(intent);
        }
    }

    private boolean isBatteryOptimizationDisabled() {
        String packageName = getPackageName();
        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
        return pm.isIgnoringBatteryOptimizations(packageName);
    }

    private AudioManager getAudioManager() {
        return (AudioManager) getSystemService(AUDIO_SERVICE);
    }

    private boolean isOnPhoneCall() {
        return isCallMode(getAudioManager().getMode());
    }

    private static boolean isCallMode(int mode) {
        return mode == AudioManager.MODE_IN_CALL || mode == AudioManager.MODE_IN_COMMUNICATION;
    }

}