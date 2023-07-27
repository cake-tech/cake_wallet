part of 'haven.dart';

class CWHavenAccountList extends HavenAccountList {
  CWHavenAccountList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Account> get accounts {
    final havenWallet = _wallet as HavenWallet;
    final accounts = havenWallet.walletAddresses.accountList.accounts
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
    return ObservableList<Account>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    havenWallet.walletAddresses.accountList.update();
  }

  @override
  void refresh(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    havenWallet.walletAddresses.accountList.refresh();
  }

  @override
  List<Account> getAll(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    return havenWallet.walletAddresses.accountList
        .getAll()
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final havenWallet = wallet as HavenWallet;
    await havenWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final havenWallet = wallet as HavenWallet;
    await havenWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}

class CWHavenSubaddressList extends MoneroSubaddressList {
  CWHavenSubaddressList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Subaddress> get subaddresses {
    final havenWallet = _wallet as HavenWallet;
    final subAddresses = havenWallet.walletAddresses.subaddressList.subaddresses
        .map((sub) => Subaddress(id: sub.id, address: sub.address, label: sub.label))
        .toList();
    return ObservableList<Subaddress>.of(subAddresses);
  }

  @override
  void update(Object wallet, {required int accountIndex}) {
    final havenWallet = wallet as HavenWallet;
    havenWallet.walletAddresses.subaddressList.update(accountIndex: accountIndex);
  }

  @override
  void refresh(Object wallet, {required int accountIndex}) {
    final havenWallet = wallet as HavenWallet;
    havenWallet.walletAddresses.subaddressList.refresh(accountIndex: accountIndex);
  }

  @override
  List<Subaddress> getAll(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    return havenWallet.walletAddresses.subaddressList
        .getAll()
        .map((sub) => Subaddress(id: sub.id, label: sub.label, address: sub.address))
        .toList();
  }

  @override
  Future<void> addSubaddress(Object wallet,
      {required int accountIndex, required String label}) async {
    final havenWallet = wallet as HavenWallet;
    await havenWallet.walletAddresses.subaddressList
        .addSubaddress(accountIndex: accountIndex, label: label);
  }

  @override
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label}) async {
    final havenWallet = wallet as HavenWallet;
    await havenWallet.walletAddresses.subaddressList
        .setLabelSubaddress(accountIndex: accountIndex, addressIndex: addressIndex, label: label);
  }
}

class CWHavenWalletDetails extends HavenWalletDetails {
  CWHavenWalletDetails(this._wallet);

  final Object _wallet;

  @computed
  @override
  Account get account {
    final havenWallet = _wallet as HavenWallet;
    final acc = havenWallet.walletAddresses.account as monero_account.Account;
    return Account(id: acc.id, label: acc.label);
  }

  @computed
  @override
  HavenBalance get balance {
    final havenWallet = _wallet as HavenWallet;
    final balance = havenWallet.balance;
    throw Exception('Unimplemented');
    //return HavenBalance(
    //	fullBalance: balance.fullBalance,
    //	unlockedBalance: balance.unlockedBalance);
  }
}

class CWHaven extends Haven {
  @override
  HavenAccountList getAccountList(Object wallet) {
    return CWHavenAccountList(wallet);
  }

  @override
  MoneroSubaddressList getSubaddressList(Object wallet) {
    return CWHavenSubaddressList(wallet);
  }

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    return havenWallet.transactionHistory;
  }

  @override
  HavenWalletDetails getMoneroWalletDetails(Object wallet) {
    return CWHavenWalletDetails(wallet);
  }

  @override
  int getHeightByDate({required DateTime date}) => getHavenHeightByDate(date: date);

  @override
  Future<int> getCurrentHeight() => getHavenCurrentHeight();

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
  WalletCredentials createHavenRestoreWalletFromKeysCredentials(
      {required String name,
      required String spendKey,
      required String viewKey,
      required String address,
      required String password,
      required String language,
      required int height}) {
    return HavenRestoreWalletFromKeysCredentials(
        name: name,
        spendKey: spendKey,
        viewKey: viewKey,
        address: address,
        password: password,
        language: language,
        height: height);
  }

  @override
  WalletCredentials createHavenRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required int height,
      required String mnemonic}) {
    return HavenRestoreWalletFromSeedCredentials(
        name: name, password: password, height: height, mnemonic: mnemonic);
  }

  @override
  WalletCredentials createHavenNewWalletCredentials(
      {required String name, required String language, String? password}) {
    return HavenNewWalletCredentials(name: name, password: password, language: language);
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    final keys = havenWallet.keys;
    return <String, String>{
      'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey
    };
  }

  @override
  Object createHavenTransactionCreationCredentials(
      {required List<Output> outputs,
      required TransactionPriority priority,
      required String assetType}) {
    return HavenTransactionCreationCredentials(
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

  @override
  Account getCurrentAccount(Object wallet) {
    final havenWallet = wallet as HavenWallet;
    final acc = havenWallet.walletAddresses.account as monero_account.Account;
    return Account(id: acc.id, label: acc.label);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label) {
    final havenWallet = wallet as HavenWallet;
    havenWallet.walletAddresses.account = monero_account.Account(id: id, label: label);
  }

  @override
  void onStartup() {
    monero_wallet_api.onStartup();
  }

  @override
  int getTransactionInfoAccountId(TransactionInfo tx) {
    final havenTransactionInfo = tx as HavenTransactionInfo;
    return havenTransactionInfo.accountIndex;
  }

  @override
  WalletService createHavenWalletService(Box<WalletInfo> walletInfoSource) {
    return HavenWalletService(walletInfoSource);
  }

  @override
  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    final havenWallet = wallet as HavenWallet;
    return havenWallet.getTransactionAddress(accountIndex, addressIndex);
  }

  @override
  CryptoCurrency assetOfTransaction(TransactionInfo tx) {
    final transaction = tx as HavenTransactionInfo;
    final asset = CryptoCurrency.fromString(transaction.assetType);
    return asset;
  }

  @override
  List<AssetRate> getAssetRate() =>
      getRate().map((rate) => AssetRate(rate.getAssetType(), rate.getRate())).toList();
}
