package com.cakewallet.cake_wallet.credentials;

import java.util.List;

public class RestoreWalletFromSeedCredentials extends Credentials {
    public String path;
    public String password;
    public String seed;
    public String passphrase;

    public RestoreWalletFromSeedCredentials(String path, String password, String seed, String passphrase) {
        this.path = path;
        this.password = password;
        this.seed = seed;
        this.passphrase = passphrase;
    }
}
