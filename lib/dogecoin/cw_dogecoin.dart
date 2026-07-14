part of 'dogecoin.dart';


class CWDogeCoin extends DogeCoin {

  @override
  WalletService createDogeCoinWalletService(Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return DogeCoinWalletService(unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createDogeCoinNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  }) =>
      DogeCoinNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        passphrase: passphrase,
        mnemonic: mnemonic,
      );

  @override
  WalletCredentials createDogeCoinRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      DogeCoinRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password, passphrase: passphrase);

  @override
  TransactionPriority deserializeDogeCoinTransactionPriority(int raw) =>
      DogecoinTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() => DogecoinTransactionPriority.medium;
  @override
  List<TransactionPriority> getTransactionPriorities() => DogecoinTransactionPriority.all;
  @override
  TransactionPriority getDogeCoinTransactionPrioritySlow() => DogecoinTransactionPriority.slow;
}
