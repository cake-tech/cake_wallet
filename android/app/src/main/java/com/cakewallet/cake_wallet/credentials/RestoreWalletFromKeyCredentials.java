package com.cakewallet.cake_wallet.credentials;

public class RestoreWalletFromKeyCredentials extends Credentials {
    public String privateKey;

    public RestoreWalletFromKeyCredentials(String privateKey) {
        this.privateKey = privateKey;
    }
}
