package com.cakewallet.cake_wallet.credentials;

public class OpenBitcoinWalletCredentials extends Credentials {
    public String path;
    public String password;

    public OpenBitcoinWalletCredentials(String path, String password) {
        this.path = path;
        this.password = password;
    }
}
