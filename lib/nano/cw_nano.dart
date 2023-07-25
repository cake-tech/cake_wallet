part of 'nano.dart';

class CWNano extends Nano {
  // @override
  // NanoAccountList getAccountList(Object wallet) {
  // 	return CWNanoAccountList(wallet);
  // }

  @override
  List<String> getNanoWordList(String language) {
    // throw UnimplementedError();
    return NanoMnemomics.WORDLIST;
  }

  @override
  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource) {
    print("creating NanoWalletService");
    return NanoWalletService(walletInfoSource);
  }

  NanoWalletDetails getNanoWalletDetails(Object wallet) {
    throw UnimplementedError();
  }

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    throw UnimplementedError();
  }

  @override
  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String? password,
  }) =>
      NanoNewWalletCredentials(
        name: name,
        password: password,
      );

  @override
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
  }) =>
      NanoRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
      );

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    // final moneroWallet = wallet as MoneroWallet;
    // return moneroWallet.transactionHistory;
    throw UnimplementedError();
  }

  @override
  void onStartup() {
    // monero_wallet_api.onStartup();
  }
}
