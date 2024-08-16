part of 'bitcoin_cash.dart';

class CWBitcoinCash extends BitcoinCash {
  @override
  String getCashAddrFormat(String address) => AddressUtils.getCashAddrFormat(address);

  @override
  WalletService createBitcoinCashWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return BitcoinCashWalletService(walletInfoSource, unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createBitcoinCashNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
  }) =>
      BitcoinCashNewWalletCredentials(name: name, walletInfo: walletInfo, password: password);

  @override
  WalletCredentials createBitcoinCashRestoreWalletFromSeedCredentials(
          {required String name, required String mnemonic, required String password}) =>
      BitcoinCashRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password);

  @override
  WalletCredentials createBitcoinCashHardwareWalletCredentials(
      {required String name, required HardwareAccountData accountData, WalletInfo? walletInfo}) =>
      BitcoinCashRestoreWalletFromHardware(
          name: name, hwAccountData: accountData, walletInfo: walletInfo);

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

  @override
  Future<List<HardwareAccountData>> getHardwareWalletAccounts(LedgerViewModel ledgerVM,
      {int index = 0, int limit = 5}) async {
    final hardwareWalletService = BitcoinCashHardwareWalletService(ledgerVM.ledger, ledgerVM.device);
    try {
      return hardwareWalletService.getAvailableAccounts(index: index, limit: limit);
    } on LedgerException catch (err) {
      print(err.message);
      throw err;
    }
  }
}
