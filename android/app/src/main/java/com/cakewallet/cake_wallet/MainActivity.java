package com.cakewallet.cake_wallet;

import android.os.Bundle;
import io.flutter.app.FlutterFragmentActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterFragmentActivity {
  private static final BitcoinWalletManagerHandler bitcoinWalletManagerHandler = new BitcoinWalletManagerHandler();

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    MethodChannel bitcoinWalletManagerChannel = new MethodChannel(getFlutterView(), BitcoinWalletManagerHandler.BITCOIN_WALLET_MANAGER_CHANNEL);
    bitcoinWalletManagerChannel.setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                bitcoinWalletManagerHandler.handle(call, result);
              }
            }
    );
  }
}
