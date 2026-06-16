part of 'nerva.dart';

class CWNervaAccountList extends NervaAccountList {
  CWNervaAccountList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Account> get accounts {
    final nervaWallet = _wallet as NervaWallet;
    final accounts = nervaWallet.walletAddresses.accountList.accounts
        .map((acc) => Account(id: acc.id, label: acc.label, balance: acc.balance))
        .toList();
    return ObservableList<Account>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    nervaWallet.walletAddresses.accountList.update();
  }

  @override
  void refresh(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    nervaWallet.walletAddresses.accountList.refresh();
  }

  @override
  List<Account> getAll(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.walletAddresses.accountList
        .getAll()
        .map((acc) => Account(id: acc.id, label: acc.label, balance: acc.balance))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final nervaWallet = wallet as NervaWallet;
    await nervaWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final nervaWallet = wallet as NervaWallet;
    await nervaWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
    if (accountIndex == nervaWallet.walletAddresses.account?.id) {
      nervaWallet.walletAddresses.account = nerva_account.Account(
          id: accountIndex, label: label, balance: nervaWallet.walletAddresses.account!.balance);
    }
  }
}

class CWNervaSubaddressList extends NervaSubaddressList {
  CWNervaSubaddressList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Subaddress> get subaddresses {
    final nervaWallet = _wallet as NervaWallet;
    final subAddresses = nervaWallet.walletAddresses.subaddressList.subaddresses
        .map((sub) => Subaddress(id: sub.id, address: sub.address, label: sub.label))
        .toList();
    return ObservableList<Subaddress>.of(subAddresses);
  }

  @override
  void update(Object wallet, {required int accountIndex}) {
    final nervaWallet = wallet as NervaWallet;
    nervaWallet.walletAddresses.subaddressList.update(accountIndex: accountIndex);
  }

  @override
  void refresh(Object wallet, {required int accountIndex}) {
    final nervaWallet = wallet as NervaWallet;
    nervaWallet.walletAddresses.subaddressList.refresh(accountIndex: accountIndex);
  }

  @override
  List<Subaddress> getAll(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.walletAddresses.subaddressList
        .getAll()
        .map((sub) => Subaddress(id: sub.id, label: sub.label, address: sub.address))
        .toList();
  }

  @override
  Future<void> addSubaddress(Object wallet,
      {required int accountIndex, required String label}) async {
    final nervaWallet = wallet as NervaWallet;
    await nervaWallet.walletAddresses.subaddressList
        .addSubaddress(accountIndex: accountIndex, label: label);
  }

  @override
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label}) async {
    final nervaWallet = wallet as NervaWallet;
    await nervaWallet.walletAddresses.subaddressList
        .setLabelSubaddress(accountIndex: accountIndex, addressIndex: addressIndex, label: label);
  }
}

class CWNervaWalletDetails extends NervaWalletDetails {
  CWNervaWalletDetails(this._wallet);

  final Object _wallet;

  @computed
  @override
  Account get account {
    final nervaWallet = _wallet as NervaWallet;
    final acc = nervaWallet.walletAddresses.account;
    return Account(id: acc!.id, label: acc.label, balance: acc.balance);
  }

  @computed
  @override
  NervaBalance get balance {
    throw Exception('Unimplemented');
    // return NervaBalance();
    //return NervaBalance(
    //	fullBalance: balance.fullBalance,
    //	unlockedBalance: balance.unlockedBalance);
  }
}

class CWNerva extends Nerva {
  @override
  NervaAccountList getAccountList(Object wallet) => CWNervaAccountList(wallet);

  @override
  NervaSubaddressList getSubaddressList(Object wallet) => CWNervaSubaddressList(wallet);

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.transactionHistory;
  }

  @override
  NervaWalletDetails getNervaWalletDetails(Object wallet) => CWNervaWalletDetails(wallet);

  @override
  int getHeightByDate({required DateTime date}) => getNervaHeightByDate(date: date);

  @override
  TransactionPriority getDefaultTransactionPriority() => MoneroTransactionPriority.automatic;

  @override
  TransactionPriority getNervaTransactionPrioritySlow() => MoneroTransactionPriority.slow;

  @override
  TransactionPriority getNervaTransactionPriorityAutomatic() =>
      MoneroTransactionPriority.automatic;

  @override
  TransactionPriority deserializeNervaTransactionPriority({required int raw}) =>
      MoneroTransactionPriority.deserialize(raw: raw);

  @override
  List<TransactionPriority> getTransactionPriorities() => MoneroTransactionPriority.all;

  @override
  List<String> getNervaWordList(String language) {
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
  WalletCredentials createNervaRestoreWalletFromKeysCredentials(
          {required String name,
          required String spendKey,
          required String viewKey,
          required String address,
          required String password,
          required String language,
          required int height}) =>
      NervaRestoreWalletFromKeysCredentials(
          name: name,
          spendKey: spendKey,
          viewKey: viewKey,
          address: address,
          password: password,
          language: language,
          height: height);

  @override
  WalletCredentials createNervaRestoreWalletFromSeedCredentials(
          {required String name,
          required String password,
          required String passphrase,
          required int height,
          required String mnemonic}) =>
      NervaRestoreWalletFromSeedCredentials(
          name: name, password: password, passphrase: passphrase, height: height, mnemonic: mnemonic);

  @override
  WalletCredentials createNervaNewWalletCredentials(
          {required String name,
          required String language,
          String? password,
          String? passphrase}) =>
      NervaNewWalletCredentials(
          name: name, password: password, language: language, passphrase: passphrase);

  @override
  Map<String, String> getKeys(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    final keys = nervaWallet.keys;
    return <String, String>{
      'privateSpendKey': keys.privateSpendKey,
      'privateViewKey': keys.privateViewKey,
      'publicSpendKey': keys.publicSpendKey,
      'publicViewKey': keys.publicViewKey,
      'passphrase': keys.passphrase
    };
  }

  @override
  int? getRestoreHeight(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.restoreHeight;
  }

  @override
  Object createNervaTransactionCreationCredentials(
          {required List<Output> outputs, required TransactionPriority priority}) =>
      NervaTransactionCreationCredentials(
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
          priority: priority as MoneroTransactionPriority);

  @override
  Object createNervaTransactionCreationCredentialsRaw(
          {required List<OutputInfo> outputs, required TransactionPriority priority}) =>
      NervaTransactionCreationCredentials(
          outputs: outputs, priority: priority as MoneroTransactionPriority);

  @override
  String formatterNervaAmountToString({required int amount}) =>
      nervaAmountToString(amount: amount);

  @override
  double formatterNervaAmountToDouble({required int amount}) =>
      nervaAmountToDouble(amount: amount);

  @override
  int formatterNervaParseAmount({required String amount}) => nervaParseAmount(amount: amount);

  @override
  Account getCurrentAccount(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    final acc = nervaWallet.walletAddresses.account;
    return Account(id: acc!.id, label: acc.label, balance: acc.balance);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label, String? balance) {
    final nervaWallet = wallet as NervaWallet;
    nervaWallet.walletAddresses.account =
        nerva_account.Account(id: id, label: label, balance: balance);
  }

  @override
  void onStartup() => nerva_wallet_api.onStartup();

  @override
  int getTransactionInfoAccountId(TransactionInfo tx) {
    final nervaTransactionInfo = tx as NervaTransactionInfo;
    return nervaTransactionInfo.accountIndex;
  }

  @override
  WalletService createNervaWalletService(Box<UnspentCoinsInfo> unspentCoinSource) =>
      NervaWalletService(unspentCoinSource);

  @override
  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.getTransactionAddress(accountIndex, addressIndex);
  }

  @override
  String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.getSubaddressLabel(accountIndex, addressIndex);
  }

  @override
  Map<String, String> pendingTransactionInfo(Object transaction) {
    final ptx = transaction as PendingNervaTransaction;
    return {'id': ptx.id, 'hex': ptx.hex, 'key': ptx.txKey};
  }

  @override
  List<Unspent> getUnspents(Object wallet) {
    final nervaWallet = wallet as NervaWallet;
    return nervaWallet.unspentCoins;
  }

  @override
  Future<void> updateUnspents(Object wallet) async {
    final nervaWallet = wallet as NervaWallet;
    await nervaWallet.updateUnspent();
  }

  @override
  Future<int> getCurrentHeight() async {
    return nerva_wallet_api.getCurrentHeight();
  }

  String getLegacySeed(Object wallet, String langName) =>
      (wallet as NervaWalletBase).seedLegacy(langName);

  @override
  void nervacCheck() {
    checkIfMoneroCIsFine();
  }

  @override
  Map<String, List<int>> debugCallLength() {
    return nerva_wallet_api.debugCallLength();
  }

  @override
  Future<void> backupSeeds(Box<HavenSeedStore> havenSeedStore) async {
    final wallets = await WalletInfo.selectList('type = ?', [WalletType.nerva.index]);
    final unspentCoinsInfo = await CakeHive.openBox<UnspentCoinsInfo>(UnspentCoinsInfo.boxName);
    for (final w in wallets) {
      final walletService = NervaWalletService(unspentCoinsInfo);
      final flutterSecureStorage = secureStorageShared;
      final keyService = KeyService(flutterSecureStorage);
      final password = await keyService.getWalletPassword(walletName: w.name);
      String seed = "unknown";
      try {
        final wallet = await walletService.openWallet(w.name, password);
        seed = wallet.seed;
        wallet.close();
      } catch (e) {
        seed += "\n$e";
      }
      await havenSeedStore.add(HavenSeedStore(id: w.id, seed: seed));
    }
    await havenSeedStore.flush();
  }
}
