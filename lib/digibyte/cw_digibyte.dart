part of 'digibyte.dart';

class CWDigibyte extends Digibyte {
  @override
  WalletService createDigibyteWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return DigibyteWalletService(walletInfoSource, unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createDigibyteNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  }) =>
      DigibyteNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        passphrase: passphrase,
        mnemonic: mnemonic,
      );

  @override
  WalletCredentials createDigibyteRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      DigibyteRestoreWalletFromSeedCredentials(
        name: name,
        mnemonic: mnemonic,
        password: password,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createDigibyteRestoreWalletFromWIFCredentials({
    required String name,
    required String password,
    required String wif,
    WalletInfo? walletInfo,
  }) =>
      DigibyteRestoreWalletFromWIFCredentials(
        name: name,
        password: password,
        wif: wif,
        walletInfo: walletInfo,
      );

  @override
  TransactionPriority deserializeDigibyteTransactionPriority(int raw) =>
      DigibyteTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() => DigibyteTransactionPriority.medium;

  @override
  List<TransactionPriority> getTransactionPriorities() => DigibyteTransactionPriority.all;

  @override
  TransactionPriority getDigibyteTransactionPrioritySlow() => DigibyteTransactionPriority.slow;
}
