part of 'bitcoin_cash.dart';

class CWBitcoinCash extends BitcoinCash {
  @override
  String getCashAddrFormat(String address) => AddressUtils.getCashAddrFormat(address);

  @override
  WalletService createBitcoinCashWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return BitcoinCashWalletService(walletInfoSource, unspentCoinSource);
  }

  @override
  WalletCredentials createBitcoinCashNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) =>
      BitcoinCashNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createBitcoinCashRestoreWalletFromSeedCredentials(
          {required String name, required String mnemonic, required String password}) =>
      BitcoinCashRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password);

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
