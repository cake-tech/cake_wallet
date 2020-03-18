package com.cakewallet.cake_wallet.credentials;

public class CreateBitcoinWalletCredentials extends Credentials {
    public String path;
    public String password;

    public CreateBitcoinWalletCredentials(String path, String password) {
        this.path = path;
        this.password = password;
    }
}
