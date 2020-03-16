package com.cakewallet.cake_wallet.tasks;

import com.cakewallet.cake_wallet.credentials.RestoreWalletFromSeedCredentials;
import com.cakewallet.cake_wallet.handlers.BitcoinWalletHandler;

import io.flutter.plugin.common.MethodChannel;

public class RestoreWalletFromSeedAsyncTask extends BitcoinWalletManagerAsyncTask<RestoreWalletFromSeedCredentials> {
    public RestoreWalletFromSeedAsyncTask(MethodChannel.Result result, BitcoinWalletHandler bitcoinWalletHandler) {
        super(result, bitcoinWalletHandler);
    }

    @Override
    protected Boolean doInBackground(RestoreWalletFromSeedCredentials... credentials) {
        boolean isRestored = false;

        try {
            isRestored = bitcoinWalletHandler.restoreWalletFromSeed(credentials[0].seed, credentials[0].passphrase);
        } catch (Exception e){
            isRestored = false;
        }

        return isRestored;
    }
}
