part of 'zano.dart';

/**class CWZanoAccountList extends ZanoAccountList {
  CWZanoAccountList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Account> get accounts {
    final zanoWallet = _wallet as ZanoWallet;
    final accounts = zanoWallet.walletAddresses.accountList.accounts
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
    return ObservableList<Account>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final zanoWallet = wallet as ZanoWallet;
    zanoWallet.walletAddresses.accountList.update();
  }

  @override
  void refresh(Object wallet) {
    final zanoWallet = wallet as ZanoWallet;
    zanoWallet.walletAddresses.accountList.refresh();
  }

  @override
  List<Account> getAll(Object wallet) {
    final zanoWallet = wallet as ZanoWallet;
    return zanoWallet.walletAddresses.accountList
        .getAll()
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final zanoWallet = wallet as ZanoWallet;
    await zanoWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final zanoWallet = wallet as ZanoWallet;
    await zanoWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}*/

class CWZanoWalletDetails extends ZanoWalletDetails {
  CWZanoWalletDetails(this._wallet);

  final Object _wallet;

  // @computed
  // @override
  // Account get account {
  //   final zanoWallet = _wallet as ZanoWallet;
  //   final acc = zanoWallet.walletAddresses.account as monero_account.Account;
  //   return Account(id: acc.id, label: acc.label);
  // }

  @computed
  @override
  ZanoBalance get balance {
    final zanoWallet = _wallet as ZanoWallet;
    final balance = zanoWallet.balance;
    return ZanoBalance(fullBalance: balance[CryptoCurrency.zano]!.total, unlockedBalance: balance[CryptoCurrency.zano]!.unlocked);
  }
}

class CWZano extends Zano {
  /**@override
  ZanoAccountList getAccountList(Object wallet) {
    return CWZanoAccountList(wallet);
  }*/

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final zanoWallet = wallet as ZanoWallet;
    return zanoWallet.transactionHistory;
  }

  @override
  ZanoWalletDetails getZanoWalletDetails(Object wallet) {
    return CWZanoWalletDetails(wallet);
  }

  @override
  TransactionPriority getDefaultTransactionPriority() {
    return MoneroTransactionPriority.automatic;
  }

  @override
  TransactionPriority deserializeMoneroTransactionPriority({required int raw}) {
    return MoneroTransactionPriority.deserialize(raw: raw);
  }

  @override
  List<TransactionPriority> getTransactionPriorities() {
    return MoneroTransactionPriority.all;
  }

  @override
  List<String> getWordList(String language) {
    assert(language.toLowerCase() == LanguageList.english.toLowerCase());
    return EnglishMnemonics.words;
  }

  @override
  WalletCredentials createZanoRestoreWalletFromKeysCredentials(
      {required String name,
      required String spendKey,
      required String viewKey,
      required String address,
      required String password,
      required String language,
      required int height}) {
    return ZanoRestoreWalletFromKeysCredentials(
        name: name,
        spendKey: spendKey,
        viewKey: viewKey,
        address: address,
        password: password,
        language: language,
        height: height);
  }

  @override
  WalletCredentials createZanoRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required int height,
      required String mnemonic}) {
    return ZanoRestoreWalletFromSeedCredentials(
        name: name, password: password, height: height, mnemonic: mnemonic);
  }

  @override
  WalletCredentials createZanoNewWalletCredentials(
      {required String name, String? password}) {
    return ZanoNewWalletCredentials(name: name, password: password);
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final zanoWallet = wallet as ZanoWallet;
    final keys = zanoWallet.keys;
    return <String, String>{
      'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey
    };
  }

  @override
  Object createZanoTransactionCreationCredentials(
      {required List<Output> outputs,
      required TransactionPriority priority,
      required String assetType}) {
    return ZanoTransactionCreationCredentials(
        outputs: outputs
            .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount))
            .toList(),
        priority: priority as MoneroTransactionPriority,
        assetType: assetType);
  }

  @override
  String formatterMoneroAmountToString({required int amount}) {
    return moneroAmountToString(amount: amount);
  }

  @override
  double formatterMoneroAmountToDouble({required int amount}) {
    return moneroAmountToDouble(amount: amount);
  }

  @override
  int formatterMoneroParseAmount({required String amount}) {
    return moneroParseAmount(amount: amount);
  }

  // @override
  // Account getCurrentAccount(Object wallet) {
  //   final zanoWallet = wallet as ZanoWallet;
  //   final acc = zanoWallet.walletAddresses.account as monero_account.Account;
  //   return Account(id: acc.id, label: acc.label);
  // }

  // @override
  // void setCurrentAccount(Object wallet, int id, String label) {
  //   final zanoWallet = wallet as ZanoWallet;
  //   zanoWallet.walletAddresses.account = monero_account.Account(id: id, label: label);
  // }

  @override
  void onStartup() {
    debugPrint("onStartup");
  }

  @override
  int getTransactionInfoAccountId(TransactionInfo tx) {
    final zanoTransactionInfo = tx as ZanoTransactionInfo;
    return zanoTransactionInfo.accountIndex;
  }

  @override
  WalletService createZanoWalletService(Box<WalletInfo> walletInfoSource) {
    return ZanoWalletService(walletInfoSource);
  }

  // @override
  // String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
  //   final zanoWallet = wallet as ZanoWallet;
  //   return zanoWallet.getTransactionAddress(accountIndex, addressIndex);
  // }

  @override
  CryptoCurrency assetOfTransaction(TransactionInfo tx) {
    final transaction = tx as ZanoTransactionInfo;
    final asset = CryptoCurrency.fromString(transaction.assetType);
    return asset;
  }

  // @override
  // List<AssetRate> getAssetRate() =>
  //     getRate().map((rate) => AssetRate(rate.getAssetType(), rate.getRate())).toList();
}
