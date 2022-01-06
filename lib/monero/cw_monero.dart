part of 'monero.dart';

class CWMoneroAccountList extends MoneroAccountList {
	CWMoneroAccountList(this._wallet);
	Object _wallet;

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
  	moneroWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet, {int accountIndex, String label}) async {
  	final moneroWallet = wallet as MoneroWallet;
  	moneroWallet.walletAddresses.accountList
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
  	moneroWallet.walletAddresses.subaddressList
  		.addSubaddress(
  			accountIndex: accountIndex,
  			label: label);
  }

  @override
  Future<void> setLabelSubaddress(Object wallet,
      {int accountIndex, int addressIndex, String label}) async {
  	final moneroWallet = wallet as MoneroWallet;
  	moneroWallet.walletAddresses.subaddressList
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
  	return MoneroBalance(
  		fullBalance: balance.fullBalance,
  		unlockedBalance: balance.unlockedBalance);
	}
}

class CWMonero extends Monero {
	MoneroAccountList getAccountList(Object wallet) {
		return CWMoneroAccountList(wallet);
	}
	
	MoneroSubaddressList getSubaddressList(Object wallet) {
		return CWMoneroSubaddressList(wallet);
	}

	TransactionHistoryBase getTransactionHistory(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
		return moneroWallet.transactionHistory;
	}

	MoneroWalletDetails getMoneroWalletDetails(Object wallet) {
		return CWMoneroWalletDetails(wallet);
	}

	int getHeigthByDate({DateTime date}) {
		return getMoneroHeigthByDate(date: date);
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
      default:
        return EnglishMnemonics.words;
    }
	}

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
	
	WalletCredentials createMoneroRestoreWalletFromSeedCredentials({String name, String password, int height, String mnemonic}) {
		return MoneroRestoreWalletFromSeedCredentials(
			name: name,
			password: password,
			height: height,
			mnemonic: mnemonic);
	}

	WalletCredentials createMoneroNewWalletCredentials({String name, String password, String language}) {
		return MoneroNewWalletCredentials(
			name: name,
			password: password,
			language: language);
	}

	Map<String, String> getKeys(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
		final keys = moneroWallet.keys;
		return <String, String>{
			'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey};
	}

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

	String formatterMoneroAmountToString({int amount}) {
		return moneroAmountToString(amount: amount);
	}

	double formatterMoneroAmountToDouble({int amount}) {
		return moneroAmountToDouble(amount: amount);
	}

	int formatterMoneroParseAmount({String amount}) {
		return moneroParseAmount(amount: amount);
	}

	Account getCurrentAccount(Object wallet) {
		final moneroWallet = wallet as MoneroWallet;
		final acc = moneroWallet.walletAddresses.account;
		return Account(id: acc.id, label: acc.label);
	}

	void setCurrentAccount(Object wallet, Account account) {
		final moneroWallet = wallet as MoneroWallet;
		moneroWallet.walletAddresses.account = monero_account.Account(id: account.id, label: account.label);
	}

	void onStartup() {
		monero_wallet_api.onStartup();
	}

	int getTransactionInfoAccountId(TransactionInfo tx) {
		final moneroTransactionInfo = tx as MoneroTransactionInfo;
		return moneroTransactionInfo.accountIndex;
	}

	WalletService createMoneroWalletService(Box<WalletInfo> walletInfoSource) {
		return MoneroWalletService(walletInfoSource);
	}
}
