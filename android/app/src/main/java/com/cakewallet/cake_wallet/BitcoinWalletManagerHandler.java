package com.cakewallet.cake_wallet;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import org.bitcoinj.core.Base58;
import org.bitcoinj.core.DumpedPrivateKey;
import org.bitcoinj.core.ECKey;
import org.bitcoinj.core.NetworkParameters;
import org.bitcoinj.params.MainNetParams;
import org.bitcoinj.script.Script;
import org.bitcoinj.wallet.DeterministicSeed;
import org.bitcoinj.wallet.Wallet;

import java.math.BigInteger;

public class BitcoinWalletManagerHandler {
    public static final String BITCOIN_WALLET_MANAGER_CHANNEL = "com.cakewallet.cake_wallet/bitcoin-wallet-manager";

    public void handle(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "createWallet":
                    createWallet(call, result);
                    break;
                case "restoreWalletFromSeed" :
                    restoreWalletFromSeed(call, result);
                    break;
                case "restoreWalletFromKeys":
                    restoreWalletFromKeys(call, result);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("UNCAUGHT_ERROR", e.getMessage(), null);
        }
    }

    private void createWallet(MethodCall call, MethodChannel.Result result) throws Exception {
        NetworkParameters params = MainNetParams.get();
        Wallet wallet = Wallet.createDeterministic(params, Script.ScriptType.P2PKH);
        ECKey key = new ECKey();
        wallet.importKey(key);
        result.success(wallet);
    }

    private void restoreWalletFromSeed(MethodCall call, MethodChannel.Result result) throws Exception {
        String seed = call.argument("seed");
        String passphrase = call.argument("passphrase");
        NetworkParameters params = MainNetParams.get();
        Long creationTime = 1409478661L;

        DeterministicSeed deterministicSeed = new DeterministicSeed(seed, null, passphrase, creationTime);
        Wallet wallet = Wallet.fromSeed(params, deterministicSeed, Script.ScriptType.P2PKH);
        result.success(wallet);
    }

    private void restoreWalletFromKeys(MethodCall call, MethodChannel.Result result) throws Exception {
        String privateKey = call.argument("privateKey");
        NetworkParameters params = MainNetParams.get();

        ECKey key;
        if (privateKey.length() == 51 || privateKey.length() == 52) {
            DumpedPrivateKey dumpedPrivateKey = DumpedPrivateKey.fromBase58(params, privateKey);
            key = dumpedPrivateKey.getKey();
        } else {
            BigInteger privKey = Base58.decodeToBigInteger(privateKey);
            key = ECKey.fromPrivate(privKey);
        }

        Wallet wallet = Wallet.createDeterministic(params, Script.ScriptType.P2PKH);
        wallet.importKey(key);
        result.success(wallet);
    }
}