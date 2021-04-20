package com.cakewallet.cake_wallet;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.unstoppabledomains.resolution.DomainResolution;
import com.unstoppabledomains.resolution.Resolution;

import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
    final String UNSTOPPABLE_DOMAIN_CHANNEL = "com.cakewallet.cake_wallet/unstoppable-domain";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        MethodChannel unstoppableDomainChannel =
                new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                        UNSTOPPABLE_DOMAIN_CHANNEL);

        unstoppableDomainChannel.setMethodCallHandler(this::handle);
    }

    private void handle(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            if (call.method.equals("getUnstoppableDomainAddress")) {
                getUnstoppableDomainAddress(call, result);
            } else {
                result.notImplemented();
            }
        } catch (Exception e) {
            result.error("UNCAUGHT_ERROR", e.getMessage(), null);
        }
    }

    private void getUnstoppableDomainAddress(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        DomainResolution resolution = new Resolution();
        Handler handler = new Handler(Looper.getMainLooper());
        String domain = call.argument("domain");
        String ticker = call.argument("ticker");

        AsyncTask.execute(() -> {
            try {
                String address = resolution.getAddress(domain, ticker);
                handler.post(() -> result.success(address));
            } catch (Exception e) {
                handler.post(() -> result.error("INVALID DOMAIN", e.getMessage(), null));
            }
        });
    }
}
