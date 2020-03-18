package com.cakewallet.cake_wallet.tasks;

import com.cakewallet.cake_wallet.credentials.RestoreWalletFromKeyCredentials;
import com.cakewallet.cake_wallet.handlers.BitcoinWalletHandler;

import io.flutter.plugin.common.MethodChannel;

public class RestoreWalletFromKeyAsyncTask extends BitcoinWalletManagerAsyncTask<RestoreWalletFromKeyCredentials> {
    public RestoreWalletFromKeyAsyncTask(MethodChannel.Result result, BitcoinWalletHandler bitcoinWalletHandler) {
        super(result, bitcoinWalletHandler);
    }

    @Override
    protected Boolean doInBackground(RestoreWalletFromKeyCredentials... credentials) {
        boolean isRestored = false;

        try {
            isRestored = bitcoinWalletHandler.restoreWalletFromKey(
                    credentials[0].path,
                    credentials[0].password,
                    credentials[0].privateKey
            );
        } catch (Exception e){
            isRestored = false;
        }

        return isRestored;
    }
}
