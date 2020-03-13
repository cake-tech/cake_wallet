package com.cakewallet.cake_wallet;

import androidx.annotation.NonNull;
import android.os.Bundle;
import io.flutter.app.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterFragmentActivity {
  private static final String BITCOIN_WALLET_MANAGER_CHANNEL = "BITCOIN_WALLET_MANAGER";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
  }

  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith((PluginRegistry) flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), BITCOIN_WALLET_MANAGER_CHANNEL)
            .setMethodCallHandler(
                    (call, result) -> new BitcoinWalletManager().onMethodCall(call, result)
            );
  }
}
