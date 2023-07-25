part of 'nano.dart';

class CWNano extends Nano {
  // @override
  // NanoAccountList getAccountList(Object wallet) {
  // 	return CWNanoAccountList(wallet);
  // }

  @override
  List<String> getNanoWordList(String language) {
    throw UnimplementedError();
  }

  @override
  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource) {
    return NanoWalletService(walletInfoSource);
    // throw UnimplementedError();
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
  }) {
    return NanoNewWalletCredentials(
      name: name,
      password: password,
    );
  }

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
