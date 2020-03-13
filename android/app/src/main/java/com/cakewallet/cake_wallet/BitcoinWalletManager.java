package com.cakewallet.cake_wallet;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.params.MainNetParams;
import org.bitcoinj.script.Script;
import org.bitcoinj.wallet.DeterministicSeed;
import org.bitcoinj.wallet.Wallet;

public class BitcoinWalletManager implements MethodChannel.MethodCallHandler {
    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "restoreWalletFromSeed" :
                try {
                    String seed = call.argument("seed");
                    Wallet wallet = restoreWalletFromSeed(seed);
                    result.success(wallet);
                } catch (Exception e) {
                    result.error("restoreError", e.getMessage(), null);
                }
                break;
            default:
                result.notImplemented();
        }
    }

    Wallet restoreWalletFromSeed(String seed) throws Exception {
        NetworkParameters params = MainNetParams.get();
        Long creationTime = 1409478661L;

        DeterministicSeed deterministicSeed = new DeterministicSeed(seed, null, "", creationTime);
        return Wallet.fromSeed(params, deterministicSeed, Script.ScriptType.P2PKH);
    }
}