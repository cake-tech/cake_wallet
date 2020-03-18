package com.cakewallet.cake_wallet.tasks;

import com.cakewallet.cake_wallet.credentials.CreateBitcoinWalletCredentials;
import com.cakewallet.cake_wallet.handlers.BitcoinWalletHandler;

import io.flutter.plugin.common.MethodChannel;

public class CreateBitcoinWalletAsyncTask extends BitcoinWalletManagerAsyncTask<CreateBitcoinWalletCredentials> {
    public CreateBitcoinWalletAsyncTask(MethodChannel.Result result, BitcoinWalletHandler bitcoinWalletHandler) {
        super(result, bitcoinWalletHandler);
    }

    @Override
    protected Boolean doInBackground(CreateBitcoinWalletCredentials... credentials) {
        boolean isCreated = false;

        try {
            isCreated = bitcoinWalletHandler.createWallet(credentials[0].path, credentials[0].password);
        } catch (Exception e) {
            isCreated = false;
        }

        return isCreated;
    }
}
