package com.cakewallet.cake_wallet;

import android.os.Bundle;
import io.flutter.app.FlutterFragmentActivity;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StringCodec;
import io.flutter.plugins.GeneratedPluginRegistrant;
import com.cakewallet.cake_wallet.handlers.*;

public class MainActivity extends FlutterFragmentActivity {
  private static final BitcoinWalletHandler bitcoinWalletHandler = new BitcoinWalletHandler();
  private static final BitcoinWalletManagerHandler bitcoinWalletManagerHandler = new BitcoinWalletManagerHandler(bitcoinWalletHandler);

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

    MethodChannel bitcoinWalletChannel = new MethodChannel(getFlutterView(), BitcoinWalletHandler.BITCOIN_WALLET_CHANNEL);

    BasicMessageChannel<String> progressChannel = new BasicMessageChannel<>(getFlutterView(), "progress_change", StringCodec.INSTANCE);
    bitcoinWalletHandler.setProgressChannel(progressChannel);

    bitcoinWalletChannel.setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
                @Override
                public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                    bitcoinWalletHandler.handle(call, result);
                }
            }
    );


  }
}
