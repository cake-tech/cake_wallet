package com.cakewallet.cake_wallet.tasks;

import com.cakewallet.cake_wallet.credentials.OpenBitcoinWalletCredentials;
import com.cakewallet.cake_wallet.handlers.BitcoinWalletHandler;

import io.flutter.plugin.common.MethodChannel;

public class OpenBitcoinWalletAsyncTask extends BitcoinWalletManagerAsyncTask<OpenBitcoinWalletCredentials> {
    public OpenBitcoinWalletAsyncTask(MethodChannel.Result result, BitcoinWalletHandler bitcoinWalletHandler) {
        super(result, bitcoinWalletHandler);
    }

    @Override
    protected Boolean doInBackground(OpenBitcoinWalletCredentials... credentials) {
        boolean isOpened = false;

        try {
            isOpened = bitcoinWalletHandler.openWallet(credentials[0].path, credentials[0].password);
        } catch (Exception e) {
            isOpened = false;
        }

        return isOpened;
    }
}
