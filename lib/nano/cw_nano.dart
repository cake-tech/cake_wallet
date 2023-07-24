part of 'nano.dart';


// class CWMoneroAccountList extends MoneroAccountList {
// 	CWMoneroAccountList(this._wallet);
// 	final Object _wallet;

// 	@override
// 	@computed
//   ObservableList<Account> get accounts {
//   	final moneroWallet = _wallet as MoneroWallet;
//   	final accounts = moneroWallet.walletAddresses.accountList
//   		.accounts
//   		.map((acc) => Account(id: acc.id, label: acc.label, balance: acc.balance))
//   		.toList();
//   	return ObservableList<Account>.of(accounts);
//   }

//   @override
//   void update(Object wallet) {
//   	final moneroWallet = wallet as MoneroWallet;
//   	moneroWallet.walletAddresses.accountList.update();
//   }

//   @override
// 	void refresh(Object wallet) {
// 		final moneroWallet = wallet as MoneroWallet;
//   	moneroWallet.walletAddresses.accountList.refresh();
// 	}

// 	@override
//   List<Account> getAll(Object wallet) {
//   	final moneroWallet = wallet as MoneroWallet;
//   	return moneroWallet.walletAddresses.accountList
//   		.getAll()
//   		.map((acc) => Account(id: acc.id, label: acc.label, balance: acc.balance))
//   		.toList();
//   }

//   @override
//   Future<void> addAccount(Object wallet, {required String label}) async {
//   	final moneroWallet = wallet as MoneroWallet;
//   	await moneroWallet.walletAddresses.accountList.addAccount(label: label);
//   }

//   @override
//   Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label}) async {
//   	final moneroWallet = wallet as MoneroWallet;
//   	await moneroWallet.walletAddresses.accountList
//   		.setLabelAccount(
//   			accountIndex: accountIndex,
//   			label: label);
//   }
// }

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
  }

  // @override
  // WalletCredentials createNanoNewWalletCredentials({
  //   required String name,
  //   WalletInfo? walletInfo,
  // }) =>
  //     NanoNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    required String language,
    String? password,
  }) {
    return NanoNewWalletCredentials(name: name, password: password, language: language);
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

  @override
  List<String> getMoneroWordList(String language) {
    throw UnimplementedError();
  }
}
