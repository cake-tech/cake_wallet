part of 'salvium.dart';

class CWSalviumAccountList extends SalviumAccountList {
  CWSalviumAccountList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Account> get accounts {
    final salviumWallet = _wallet as SalviumWallet;
    final accounts = salviumWallet.walletAddresses.accountList.accounts
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
    return ObservableList<Account>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.accountList.update();
  }

  @override
  void refresh(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.accountList.refresh();
  }

  @override
  List<Account> getAll(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.walletAddresses.accountList
        .getAll()
        .map((acc) => Account(id: acc.id, label: acc.label))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final salviumWallet = wallet as SalviumWallet;
    await salviumWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final salviumWallet = wallet as SalviumWallet;
    await salviumWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}

class CWSalviumSubaddressList extends MoneroSubaddressList {
  CWSalviumSubaddressList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Subaddress> get subaddresses {
    final salviumWallet = _wallet as SalviumWallet;
    final subAddresses = salviumWallet.walletAddresses.subaddressList.subaddresses
        .map((sub) => Subaddress(id: sub.id, address: sub.address, label: sub.label))
        .toList();
    return ObservableList<Subaddress>.of(subAddresses);
  }

  @override
  void update(Object wallet, {required int accountIndex}) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.subaddressList.update(accountIndex: accountIndex);
  }

  @override
  void refresh(Object wallet, {required int accountIndex}) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.subaddressList.refresh(accountIndex: accountIndex);
  }

  @override
  List<Subaddress> getAll(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.walletAddresses.subaddressList
        .getAll()
        .map((sub) => Subaddress(id: sub.id, label: sub.label, address: sub.address))
        .toList();
  }

  @override
  Future<void> addSubaddress(Object wallet,
      {required int accountIndex, required String label}) async {
    final salviumWallet = wallet as SalviumWallet;
    await salviumWallet.walletAddresses.subaddressList
        .addSubaddress(accountIndex: accountIndex, label: label);
  }

  @override
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label}) async {
    final salviumWallet = wallet as SalviumWallet;
    await salviumWallet.walletAddresses.subaddressList
        .setLabelSubaddress(accountIndex: accountIndex, addressIndex: addressIndex, label: label);
  }
}

class CWSalviumWalletDetails extends SalviumWalletDetails {
  CWSalviumWalletDetails(this._wallet);

  final Object _wallet;

  @computed
  @override
  Account get account {
    final salviumWallet = _wallet as SalviumWallet;
    final acc = salviumWallet.walletAddresses.account as monero_account.Account;
    return Account(id: acc.id, label: acc.label);
  }

  @computed
  @override
  SalviumBalance get balance {
    final salviumWallet = _wallet as SalviumWallet;
    final balance = salviumWallet.balance;
    throw Exception('Unimplemented');
    //return SalviumBalance(
    //	fullBalance: balance.fullBalance,
    //	unlockedBalance: balance.unlockedBalance);
  }
}

class CWSalvium extends Salvium {
  @override
  SalviumAccountList getAccountList(Object wallet) {
    return CWSalviumAccountList(wallet);
  }

  @override
  MoneroSubaddressList getSubaddressList(Object wallet) {
    return CWSalviumSubaddressList(wallet);
  }

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.transactionHistory;
  }

  @override
  SalviumWalletDetails getMoneroWalletDetails(Object wallet) {
    return CWSalviumWalletDetails(wallet);
  }

  @override
  int getHeightByDate({required DateTime date}) => getSalviumHeightByDate(date: date);

  @override
  Future<int> getCurrentHeight() => getSalviumCurrentHeight();

  @override
  TransactionPriority getDefaultTransactionPriority() {
    return SalviumTransactionPriority.automatic;
  }

  @override
  TransactionPriority deserializeMoneroTransactionPriority({required int raw}) {
    return SalviumTransactionPriority.deserialize(raw: raw);
  }

  @override
  List<TransactionPriority> getTransactionPriorities() {
    return SalviumTransactionPriority.all;
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
  WalletCredentials createSalviumRestoreWalletFromKeysCredentials(
      {required String name,
      required String spendKey,
      required String viewKey,
      required String address,
      required String password,
      required String language,
      required int height}) {
    return SalviumRestoreWalletFromKeysCredentials(
        name: name,
        spendKey: spendKey,
        viewKey: viewKey,
        address: address,
        password: password,
        language: language,
        height: height);
  }

  @override
  WalletCredentials createSalviumRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required int height,
      required String mnemonic}) {
    return SalviumRestoreWalletFromSeedCredentials(
        name: name, password: password, height: height, mnemonic: mnemonic);
  }

  @override
  WalletCredentials createSalviumNewWalletCredentials(
      {required String name, required String language, String? password}) {
    return SalviumNewWalletCredentials(name: name, password: password, language: language);
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    final keys = salviumWallet.keys;
    return <String, String>{
      'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey
    };
  }

  @override
  Object createSalviumTransactionCreationCredentials(
      {required List<Output> outputs,
      required TransactionPriority priority,
      required String assetType}) {
    return SalviumTransactionCreationCredentials(
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
        priority: priority as SalviumTransactionPriority,
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
    final salviumWallet = wallet as SalviumWallet;
    final acc = salviumWallet.walletAddresses.account as monero_account.Account;
    return Account(id: acc.id, label: acc.label);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.account = monero_account.Account(id: id, label: label);
  }

  @override
  void onStartup() {
    monero_wallet_api.onStartup();
  }

  @override
  int getTransactionInfoAccountId(TransactionInfo tx) {
    final salviumTransactionInfo = tx as SalviumTransactionInfo;
    return salviumTransactionInfo.accountIndex;
  }

  @override
  WalletService createSalviumWalletService(Box<WalletInfo> walletInfoSource) {
    return SalviumWalletService(walletInfoSource);
  }

  @override
  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.getTransactionAddress(accountIndex, addressIndex);
  }

  @override
  CryptoCurrency assetOfTransaction(TransactionInfo tx) {
    final transaction = tx as SalviumTransactionInfo;
    final asset = CryptoCurrency.fromString(transaction.assetType);
    return asset;
  }

  @override
  List<AssetRate> getAssetRate() =>
      getRate().map((rate) => AssetRate(rate.getAssetType(), rate.getRate())).toList();
}
