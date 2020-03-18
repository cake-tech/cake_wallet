package com.cakewallet.cake_wallet.credentials;

public class RestoreWalletFromKeyCredentials extends Credentials {
    public String path;
    public String password;
    public String privateKey;

    public RestoreWalletFromKeyCredentials(String path, String password, String privateKey) {
        this.path = path;
        this.password = password;
        this.privateKey = privateKey;
    }
}
