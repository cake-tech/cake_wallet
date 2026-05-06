package com.cakewallet.cake_wallet;

import io.flutter.app.FlutterApplication;

public class Application extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        StarknetRust.ensureInitialized(this);
    }
}
