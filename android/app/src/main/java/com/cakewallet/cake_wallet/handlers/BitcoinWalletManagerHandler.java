package com.cakewallet.cake_wallet.handlers;

import android.os.AsyncTask;

import com.cakewallet.cake_wallet.credentials.CreateBitcoinWalletCredentials;
import com.cakewallet.cake_wallet.credentials.OpenBitcoinWalletCredentials;
import com.cakewallet.cake_wallet.credentials.RestoreWalletFromKeyCredentials;
import com.cakewallet.cake_wallet.credentials.RestoreWalletFromSeedCredentials;
import com.cakewallet.cake_wallet.tasks.CreateBitcoinWalletAsyncTask;
import com.cakewallet.cake_wallet.tasks.OpenBitcoinWalletAsyncTask;
import com.cakewallet.cake_wallet.tasks.RestoreWalletFromKeyAsyncTask;
import com.cakewallet.cake_wallet.tasks.RestoreWalletFromSeedAsyncTask;

import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class BitcoinWalletManagerHandler {
    public static final String BITCOIN_WALLET_MANAGER_CHANNEL = "com.cakewallet.cake_wallet/bitcoin-wallet-manager";
    private BitcoinWalletHandler bitcoinWalletHandler;

    public BitcoinWalletManagerHandler(BitcoinWalletHandler bitcoinWalletHandler) {
        this.bitcoinWalletHandler = bitcoinWalletHandler;
    }

    public void handle(MethodCall call, MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "createWallet":
                    createWallet(call, result);
                    break;
                case "openWallet":
                    openWallet(call, result);
                    break;
                case "restoreWalletFromSeed" :
                    restoreWalletFromSeed(call, result);
                    break;
                case "restoreWalletFromKey":
                    restoreWalletFromKey(call, result);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Exception e) {
            result.error("UNCAUGHT_ERROR", e.getMessage(), null);
        }
    }

    private void createWallet(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        String password = call.argument("password");

        CreateBitcoinWalletAsyncTask createBitcoinWalletAsyncTask = new CreateBitcoinWalletAsyncTask(result, bitcoinWalletHandler);
        CreateBitcoinWalletCredentials credentials = new CreateBitcoinWalletCredentials(path, password);
        createBitcoinWalletAsyncTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, credentials);
    }

    private void openWallet(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        String password = call.argument("password");

        OpenBitcoinWalletAsyncTask openBitcoinWalletAsyncTask = new OpenBitcoinWalletAsyncTask(result, bitcoinWalletHandler);
        OpenBitcoinWalletCredentials credentials = new OpenBitcoinWalletCredentials(path, password);
        openBitcoinWalletAsyncTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, credentials);
    }

    private void restoreWalletFromSeed(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        String password = call.argument("password");
        List<String> seed = call.argument("seed");
        String passphrase = call.argument("passphrase");

        RestoreWalletFromSeedAsyncTask restoreWalletFromSeedAsyncTask = new RestoreWalletFromSeedAsyncTask(result, bitcoinWalletHandler);
        RestoreWalletFromSeedCredentials credentials = new RestoreWalletFromSeedCredentials(path, password, seed, passphrase);
        restoreWalletFromSeedAsyncTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, credentials);
    }

    private void restoreWalletFromKey(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        String password = call.argument("password");
        String privateKey = call.argument("privateKey");

        RestoreWalletFromKeyAsyncTask restoreWalletFromKeyAsyncTask = new RestoreWalletFromKeyAsyncTask(result, bitcoinWalletHandler);
        RestoreWalletFromKeyCredentials credentials = new RestoreWalletFromKeyCredentials(path, password, privateKey);
        restoreWalletFromKeyAsyncTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, credentials);
    }
}