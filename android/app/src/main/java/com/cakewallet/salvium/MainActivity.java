package com.cakewallet.salvium;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import android.os.AsyncTask;
import android.os.Build;
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

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel utilsChannel =
                new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                        UTILS_CHANNEL);

        utilsChannel.setMethodCallHandler(this::handle);
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
                case "disableBatteryOptimization":
                    disableBatteryOptimization();
                    handler.post(() -> result.success(null));
                    break;
                case "isBatteryOptimizationDisabled":
                    boolean isDisabled = isBatteryOptimizationDisabled();
                    handler.post(() -> result.success(isDisabled));
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

}