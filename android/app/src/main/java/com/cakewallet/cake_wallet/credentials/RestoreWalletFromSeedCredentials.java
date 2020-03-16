package com.cakewallet.cake_wallet.credentials;

public class RestoreWalletFromSeedCredentials extends Credentials {
    public String seed;
    public String passphrase;

    public RestoreWalletFromSeedCredentials(String seed, String passphrase) {
        this.seed = seed;
        this.passphrase = passphrase;
    }
}
