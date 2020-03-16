package com.cakewallet.cake_wallet.tasks;

import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;

import com.cakewallet.cake_wallet.credentials.Credentials;
import com.cakewallet.cake_wallet.handlers.BitcoinWalletHandler;

import io.flutter.plugin.common.MethodChannel;

public abstract class BitcoinWalletManagerAsyncTask<Creds extends Credentials> extends AsyncTask<Creds, Void, Boolean> {
    protected MethodChannel.Result result;
    protected BitcoinWalletHandler bitcoinWalletHandler;

    BitcoinWalletManagerAsyncTask(MethodChannel.Result result, BitcoinWalletHandler bitcoinWalletHandler) {
        this.result = result;
        this.bitcoinWalletHandler = bitcoinWalletHandler;
    }

    protected void onPostExecute(Boolean res) {
        new Handler(Looper.getMainLooper())
                .post(() -> result.success(res));
    }
}
