part of 'bitcoin_cash.dart';

class CWBitcoinCash extends BitcoinCash {
  @override
  String getCashAddrFormat(String address) => AddressUtils.getCashAddrFormat(address);

  @override
  WalletService createBitcoinCashWalletService(Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return BitcoinCashWalletService(unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createBitcoinCashNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  }) =>
      BitcoinCashNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        passphrase: passphrase,
        mnemonic: mnemonic,
      );

  @override
  WalletCredentials createBitcoinCashRestoreWalletFromSeedCredentials(
          {required String name, required String mnemonic, required String password, String? passphrase}) =>
      BitcoinCashRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password, passphrase: passphrase);

  @override
  TransactionPriority deserializeBitcoinCashTransactionPriority(int raw) =>
      BitcoinCashTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() => BitcoinCashTransactionPriority.medium;

  @override
  List<TransactionPriority> getTransactionPriorities() => BitcoinCashTransactionPriority.all;

  @override
  TransactionPriority getBitcoinCashTransactionPrioritySlow() =>
      BitcoinCashTransactionPriority.slow;
}
