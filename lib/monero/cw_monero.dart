part of 'monero.dart';

class CWMoneroAccountList extends MoneroAccountList {
	CWMoneroAccountList(this._wallet);
	final Object _wallet;

	@override
	@computed
  ObservableList<Account> get accounts {
  	final moneroWallet = _wallet as MoneroWallet;
  	final accounts = moneroWallet.walletAddresses.accountList
  		.accounts
  		.map((acc) => Account(id: acc.id, label: acc.label))
  		.toList();
  	return ObservableList<Account>.of(accounts);
  }

  @override
  void update(Object wallet) {
  	final moneroWallet = wallet as MoneroWallet;
  	moneroWallet.walletAddresses.accountList.update();
  }

  @override
	void refresh(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
  	moneroWallet.walletAddresses.accountList.refresh();
	}

	@override
  List<Account> getAll(Object wallet) {
  	final moneroWallet = wallet as MoneroWallet;
  	return moneroWallet.walletAddresses.accountList
  		.getAll()
  		.map((acc) => Account(id: acc.id, label: acc.label))
  		.toList();
  }

  @override
  Future<void> addAccount(Object wallet, {String label}) async {
  	final moneroWallet = wallet as MoneroWallet;
  	await moneroWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet, {int accountIndex, String label}) async {
  	final moneroWallet = wallet as MoneroWallet;
  	await moneroWallet.walletAddresses.accountList
  		.setLabelAccount(
  			accountIndex: accountIndex,
  			label: label);
  }
}

class CWMoneroSubaddressList extends MoneroSubaddressList {
	CWMoneroSubaddressList(this._wallet);
	Object _wallet;

	@override
	@computed
  ObservableList<Subaddress> get subaddresses {
  	final moneroWallet = _wallet as MoneroWallet;
  	final subAddresses = moneroWallet.walletAddresses.subaddressList
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
  	final moneroWallet = wallet as MoneroWallet;
  	moneroWallet.walletAddresses.subaddressList.update(accountIndex: accountIndex);
  }

  @override
  void refresh(Object wallet, {int accountIndex}) {
  	final moneroWallet = wallet as MoneroWallet;
  	moneroWallet.walletAddresses.subaddressList.refresh(accountIndex: accountIndex);
  }

  @override
  List<Subaddress> getAll(Object wallet) {
  	final moneroWallet = wallet as MoneroWallet;
  	return moneroWallet.walletAddresses
  		.subaddressList
  		.getAll()
  		.map((sub) => Subaddress(id: sub.id, label: sub.label, address: sub.address))
  		.toList();
  }

  @override
  Future<void> addSubaddress(Object wallet, {int accountIndex, String label}) async {
  	final moneroWallet = wallet as MoneroWallet;
  	await moneroWallet.walletAddresses.subaddressList
  		.addSubaddress(
  			accountIndex: accountIndex,
  			label: label);
  }

  @override
  Future<void> setLabelSubaddress(Object wallet,
      {int accountIndex, int addressIndex, String label}) async {
  	final moneroWallet = wallet as MoneroWallet;
  	await moneroWallet.walletAddresses.subaddressList
  		.setLabelSubaddress(
  			accountIndex: accountIndex,
  			addressIndex: addressIndex,
  			label: label);
  }
}

class CWMoneroWalletDetails extends MoneroWalletDetails {
	CWMoneroWalletDetails(this._wallet);
	Object _wallet;

	@computed
  Account get account {
  	final moneroWallet = _wallet as MoneroWallet;
  	final acc = moneroWallet.walletAddresses.account;
  	return Account(id: acc.id, label: acc.label);
  }

  @computed
	MoneroBalance get balance {
		final moneroWallet = _wallet as MoneroWallet;
  	final balance = moneroWallet.balance;
  	return MoneroBalance();
  	//return MoneroBalance(
  	//	fullBalance: balance.fullBalance,
  	//	unlockedBalance: balance.unlockedBalance);
	}
}

class CWMonero extends Monero {
	MoneroAccountList getAccountList(Object wallet) {
		return CWMoneroAccountList(wallet);
	}
	
	@override
	MoneroSubaddressList getSubaddressList(Object wallet) {
		return CWMoneroSubaddressList(wallet);
	}

	@override
	TransactionHistoryBase getTransactionHistory(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
		return moneroWallet.transactionHistory;
	}

	@override
	MoneroWalletDetails getMoneroWalletDetails(Object wallet) {
		return CWMoneroWalletDetails(wallet);
	}

	@override
	int getHeigthByDate({DateTime date}) {
		return getMoneroHeigthByDate(date: date);
	}
	
	@override
	TransactionPriority getDefaultTransactionPriority() {
		return MoneroTransactionPriority.slow;
	}

	@override
	TransactionPriority deserializeMoneroTransactionPriority({int raw}) {
		return MoneroTransactionPriority.deserialize(raw: raw);
	}

	@override
	List<TransactionPriority> getTransactionPriorities() {
		return MoneroTransactionPriority.all;
	}

	@override
	List<String> getMoneroWordList(String language) {
		switch (language.toLowerCase()) {
		  case 'english':
		    return EnglishMnemonics.words;
		  case 'chinese (simplified)':
		    return ChineseSimplifiedMnemonics.words;
		  case 'dutch':
		    return DutchMnemonics.words;
		  case 'german':
		    return GermanMnemonics.words;
		  case 'japanese':
		    return JapaneseMnemonics.words;
		  case 'portuguese':
		    return PortugueseMnemonics.words;
		  case 'russian':
		    return RussianMnemonics.words;
		  case 'spanish':
		    return SpanishMnemonics.words;
		  case 'french':
		  	return FrenchMnemonics.words;
		  case 'italian':
		  	return ItalianMnemonics.words;
		  default:
		    return EnglishMnemonics.words;
		}
	}

	@override
	WalletCredentials createMoneroRestoreWalletFromKeysCredentials({
			String name,
    	String spendKey,
    	String viewKey,
    	String address,
    	String password,
    	String language,
    	int height}) {
		return MoneroRestoreWalletFromKeysCredentials(
			name: name,
			spendKey: spendKey,
			viewKey: viewKey,
			address: address,
			password: password,
			language: language,
			height: height);
	}
	
	@override
	WalletCredentials createMoneroRestoreWalletFromSeedCredentials({String name, String password, int height, String mnemonic}) {
		return MoneroRestoreWalletFromSeedCredentials(
			name: name,
			password: password,
			height: height,
			mnemonic: mnemonic);
	}

	@override
	WalletCredentials createMoneroNewWalletCredentials({String name, String password, String language}) {
		return MoneroNewWalletCredentials(
			name: name,
			password: password,
			language: language);
	}

	@override
	Map<String, String> getKeys(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
		final keys = moneroWallet.keys;
		return <String, String>{
			'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey};
	}

	@override
	Object createMoneroTransactionCreationCredentials({List<Output> outputs, TransactionPriority priority}) {
		return MoneroTransactionCreationCredentials(
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

	@override
	Object createMoneroTransactionCreationCredentialsRaw({List<OutputInfo> outputs, TransactionPriority priority}) {
		return MoneroTransactionCreationCredentials(
			outputs: outputs,
			priority: priority as MoneroTransactionPriority);
	}

	@override
	String formatterMoneroAmountToString({int amount}) {
		return moneroAmountToString(amount: amount);
	}

	@override
	double formatterMoneroAmountToDouble({int amount}) {
		return moneroAmountToDouble(amount: amount);
	}

	@override
	int formatterMoneroParseAmount({String amount}) {
		return moneroParseAmount(amount: amount);
	}

	@override
	Account getCurrentAccount(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
		final acc = moneroWallet.walletAddresses.account;
		return Account(id: acc.id, label: acc.label);
	}

	@override
	void setCurrentAccount(Object wallet, int id, String label) {
		final moneroWallet = wallet as MoneroWallet;
		moneroWallet.walletAddresses.account = monero_account.Account(id: id, label: label);
	}

	@override
	void onStartup() {
		monero_wallet_api.onStartup();
	}

	@override
	int getTransactionInfoAccountId(TransactionInfo tx) {
		final moneroTransactionInfo = tx as MoneroTransactionInfo;
		return moneroTransactionInfo.accountIndex;
	}

	@override
	WalletService createMoneroWalletService(Box<WalletInfo> walletInfoSource) {
		return MoneroWalletService(walletInfoSource);
	}

	@override
	String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
		final moneroWallet = wallet as MoneroWallet;
		return moneroWallet.getTransactionAddress(accountIndex, addressIndex);
	}

	@override
	String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex) {
		final moneroWallet = wallet as MoneroWallet;
		return moneroWallet.getSubaddressLabel(accountIndex, addressIndex);
	}

	@override
	Map<String, String> pendingTransactionInfo(Object transaction) {
		final ptx = transaction as PendingMoneroTransaction;
		return {'id': ptx.id, 'hex': ptx.hex, 'key': ptx.txKey};
	}
}
