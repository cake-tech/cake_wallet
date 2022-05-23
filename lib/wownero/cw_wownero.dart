part of 'wownero.dart';

class CWWowneroAccountList extends WowneroAccountList {
	CWWowneroAccountList(this._wallet);
	Object _wallet;

	@override
	@computed
	ObservableList<Account> get accounts {
		final wowneroWallet = _wallet as WowneroWallet;
		final accounts = wowneroWallet.walletAddresses.accountList
				.accounts
				.map((acc) => Account(id: acc.id, label: acc.label))
				.toList();
		return ObservableList<Account>.of(accounts);
	}

	@override
	void update(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.accountList.update();
	}

	@override
	void refresh(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.accountList.refresh();
	}

	@override
	List<Account> getAll(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		return wowneroWallet.walletAddresses.accountList
				.getAll()
				.map((acc) => Account(id: acc.id, label: acc.label))
				.toList();
	}

	@override
	Future<void> addAccount(Object wallet, {String label}) async {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.accountList.addAccount(label: label);
	}

	@override
	Future<void> setLabelAccount(Object wallet, {int accountIndex, String label}) async {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.accountList
				.setLabelAccount(
				accountIndex: accountIndex,
				label: label);
	}
}

class CWWowneroSubaddressList extends WowneroSubaddressList {
	CWWowneroSubaddressList(this._wallet);
	Object _wallet;

	@override
	@computed
	ObservableList<Subaddress> get subaddresses {
		final wowneroWallet = _wallet as WowneroWallet;
		final subAddresses = wowneroWallet.walletAddresses.subaddressList
				.subaddresses
				.map((sub) => Subaddress(
				id: sub.id,
				address: sub.address,
				label: sub.label))
				.toList();
		return ObservableList<Subaddress>.of(subAddresses);
	}

	@override
	void update(Object wallet, {int accountIndex}) {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.subaddressList.update(accountIndex: accountIndex);
	}

	@override
	void refresh(Object wallet, {int accountIndex}) {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.subaddressList.refresh(accountIndex: accountIndex);
	}

	@override
	List<Subaddress> getAll(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		return wowneroWallet.walletAddresses
				.subaddressList
				.getAll()
				.map((sub) => Subaddress(id: sub.id, label: sub.label, address: sub.address))
				.toList();
	}

	@override
	Future<void> addSubaddress(Object wallet, {int accountIndex, String label}) async {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.subaddressList
				.addSubaddress(
				accountIndex: accountIndex,
				label: label);
	}

	@override
	Future<void> setLabelSubaddress(Object wallet,
			{int accountIndex, int addressIndex, String label}) async {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.subaddressList
				.setLabelSubaddress(
				accountIndex: accountIndex,
				addressIndex: addressIndex,
				label: label);
	}
}

class CWWowneroWalletDetails extends WowneroWalletDetails {
	CWWowneroWalletDetails(this._wallet);
	Object _wallet;

	@computed
	Account get account {
		final wowneroWallet = _wallet as WowneroWallet;
		final acc = wowneroWallet.walletAddresses.account;
		return Account(id: acc.id, label: acc.label);
	}

	@computed
	WowneroBalance get balance {
		final wowneroWallet = _wallet as WowneroWallet;
		final balance = wowneroWallet.balance;
		return WowneroBalance();
		//return WowneroBalance(
		//	fullBalance: balance.fullBalance,
		//	unlockedBalance: balance.unlockedBalance);
	}
}

class CWWownero extends Wownero {
	WowneroAccountList getAccountList(Object wallet) {
		return CWWowneroAccountList(wallet);
	}

	WowneroSubaddressList getSubaddressList(Object wallet) {
		return CWWowneroSubaddressList(wallet);
	}

	TransactionHistoryBase getTransactionHistory(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		return wowneroWallet.transactionHistory;
	}

	WowneroWalletDetails getWowneroWalletDetails(Object wallet) {
		return CWWowneroWalletDetails(wallet);
	}

	TransactionPriority getDefaultTransactionPriority() {
		return MoneroTransactionPriority.slow;
	}

	TransactionPriority deserializeMoneroTransactionPriority({int raw}) {
		return MoneroTransactionPriority.deserialize(raw: raw);
	}

	List<TransactionPriority> getTransactionPriorities() {
		return MoneroTransactionPriority.all;
	}

	List<String> getWowneroWordList(String language) {
		switch (language.toLowerCase()) {
			case 'english':
				return EnglishMnemonics.words;
			default:
				return EnglishMnemonics.words;
		}
	}

	WalletCredentials createWowneroRestoreWalletFromKeysCredentials({
		String name,
		String spendKey,
		String viewKey,
		String address,
		String password,
		String language,
		int height}) {
		return WowneroRestoreWalletFromKeysCredentials(
				name: name,
				spendKey: spendKey,
				viewKey: viewKey,
				address: address,
				password: password,
				language: language,
				height: height);
	}

	WalletCredentials createWowneroRestoreWalletFromSeedCredentials({String name, String password, int height, String mnemonic}) {
		return WowneroRestoreWalletFromSeedCredentials(
				name: name,
				password: password,
				height: height,
				mnemonic: mnemonic);
	}

	WalletCredentials createWowneroNewWalletCredentials({String name, String password, String language}) {
		return WowneroNewWalletCredentials(
				name: name,
				password: password,
				language: language);
	}

	Map<String, String> getKeys(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		final keys = wowneroWallet.keys;
		return <String, String>{
			'privateSpendKey': keys.privateSpendKey,
			'privateViewKey': keys.privateViewKey,
			'publicSpendKey': keys.publicSpendKey,
			'publicViewKey': keys.publicViewKey};
	}

	Object createWowneroTransactionCreationCredentials({List<Output> outputs, TransactionPriority priority}) {
		return WowneroTransactionCreationCredentials(
				outputs: outputs.map((out) => OutputInfo(
						fiatAmount: out.fiatAmount,
						cryptoAmount: out.cryptoAmount,
						address: out.address,
						note: out.note,
						sendAll: out.sendAll,
						extractedAddress: out.extractedAddress,
						isParsedAddress: out.isParsedAddress,
						formattedCryptoAmount: out.formattedCryptoAmount))
						.toList(),
				priority: priority as MoneroTransactionPriority);
	}

	String formatterWowneroAmountToString({int amount}) {
		return wowneroAmountToString(amount: amount);
	}

	double formatterWowneroAmountToDouble({int amount}) {
		return wowneroAmountToDouble(amount: amount);
	}

	int formatterWowneroParseAmount({String amount}) {
		return wowneroParseAmount(amount: amount);
	}

	Account getCurrentAccount(Object wallet) {
		final wowneroWallet = wallet as WowneroWallet;
		final acc = wowneroWallet.walletAddresses.account;
		return Account(id: acc.id, label: acc.label);
	}

	void setCurrentAccount(Object wallet, int id, String label) {
		final wowneroWallet = wallet as WowneroWallet;
		wowneroWallet.walletAddresses.account = wownero_account.Account(id: id, label: label);
	}

	void onStartup() {
		wownero_wallet_api.onStartup();
	}

	int getTransactionInfoAccountId(TransactionInfo tx) {
		final wowneroTransactionInfo = tx as WowneroTransactionInfo;
		return wowneroTransactionInfo.accountIndex;
	}

	WalletService createWowneroWalletService(Box<WalletInfo> walletInfoSource) {
		return WowneroWalletService(walletInfoSource);
	}

	String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
		final wowneroWallet = wallet as WowneroWallet;
		return wowneroWallet.getTransactionAddress(accountIndex, addressIndex);
	}

	String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex) {
		final wowneroWallet = wallet as WowneroWallet;
		return wowneroWallet.getSubaddressLabel(accountIndex, addressIndex);
	}
}
