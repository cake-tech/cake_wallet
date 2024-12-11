part of 'salvium.dart';

class CWSalviumAccountList extends SalviumAccountList {
  CWSalviumAccountList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Account> get accounts {
    final salviumWallet = _wallet as SalviumWallet;
    final accounts = salviumWallet.walletAddresses.accountList.accounts
        .map((acc) =>
            Account(id: acc.id, label: acc.label, balance: acc.balance))
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
        .map((acc) =>
            Account(id: acc.id, label: acc.label, balance: acc.balance))
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

class CWSalviumSubaddressList extends SalviumSubaddressList {
  CWSalviumSubaddressList(this._wallet);

  final Object _wallet;

  @override
  @computed
  ObservableList<Subaddress> get subaddresses {
    final salviumWallet = _wallet as SalviumWallet;
    final subAddresses = salviumWallet
        .walletAddresses.subaddressList.subaddresses
        .map((sub) =>
            Subaddress(id: sub.id, address: sub.address, label: sub.label))
        .toList();
    return ObservableList<Subaddress>.of(subAddresses);
  }

  @override
  void update(Object wallet, {required int accountIndex}) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.subaddressList
        .update(accountIndex: accountIndex);
  }

  @override
  void refresh(Object wallet, {required int accountIndex}) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.subaddressList
        .refresh(accountIndex: accountIndex);
  }

  @override
  List<Subaddress> getAll(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.walletAddresses.subaddressList
        .getAll()
        .map((sub) =>
            Subaddress(id: sub.id, label: sub.label, address: sub.address))
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
      {required int accountIndex,
      required int addressIndex,
      required String label}) async {
    final salviumWallet = wallet as SalviumWallet;
    await salviumWallet.walletAddresses.subaddressList.setLabelSubaddress(
        accountIndex: accountIndex, addressIndex: addressIndex, label: label);
  }
}

class CWSalviumWalletDetails extends SalviumWalletDetails {
  CWSalviumWalletDetails(this._wallet);

  final Object _wallet;

  @computed
  @override
  Account get account {
    final salviumWallet = _wallet as SalviumWallet;
    final acc = salviumWallet.walletAddresses.account;
    return Account(id: acc!.id, label: acc.label, balance: acc.balance);
  }

  @computed
  @override
  SalviumBalance get balance {
    throw Exception('Unimplemented');
    // return SalviumBalance();
    //return SalviumBalance(
    //	fullBalance: balance.fullBalance,
    //	unlockedBalance: balance.unlockedBalance);
  }
}

class CWSalvium extends Salvium {
  @override
  SalviumAccountList getAccountList(Object wallet) =>
      CWSalviumAccountList(wallet);

  @override
  SalviumSubaddressList getSubaddressList(Object wallet) =>
      CWSalviumSubaddressList(wallet);

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.transactionHistory;
  }

  @override
  SalviumWalletDetails getSalviumWalletDetails(Object wallet) =>
      CWSalviumWalletDetails(wallet);

  @override
  int getHeightByDate({required DateTime date}) =>
      getSalviumHeightByDate(date: date);

  @override
  TransactionPriority getDefaultTransactionPriority() =>
      MoneroTransactionPriority.automatic;

  @override
  TransactionPriority getSalviumTransactionPrioritySlow() =>
      MoneroTransactionPriority.slow;

  @override
  TransactionPriority getSalviumTransactionPriorityAutomatic() =>
      MoneroTransactionPriority.automatic;

  @override
  TransactionPriority deserializeSalviumTransactionPriority(
          {required int raw}) =>
      MoneroTransactionPriority.deserialize(raw: raw);

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      MoneroTransactionPriority.all;

  @override
  List<String> getSalviumWordList(String language) {
    if (language.startsWith("POLYSEED_")) {
      final lang = language.replaceAll("POLYSEED_", "");
      return PolyseedLang.getByEnglishName(lang).words;
    }
    if (language.startsWith("WOWSEED_")) {
      final lang = language.replaceAll("WOWSEED_", "");
      return PolyseedLang.getByEnglishName(lang).words;
    }
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
          required int height}) =>
      SalviumRestoreWalletFromKeysCredentials(
          name: name,
          spendKey: spendKey,
          viewKey: viewKey,
          address: address,
          password: password,
          language: language,
          height: height);

  @override
  WalletCredentials createSalviumRestoreWalletFromSeedCredentials(
          {required String name,
          required String password,
          required int height,
          required String mnemonic}) =>
      SalviumRestoreWalletFromSeedCredentials(
          name: name, password: password, height: height, mnemonic: mnemonic);

  @override
  WalletCredentials createSalviumNewWalletCredentials(
          {required String name,
          required String language,
          required bool isPolyseed,
          String? password}) =>
      SalviumNewWalletCredentials(
          name: name,
          password: password,
          language: language,
          isPolyseed: isPolyseed);

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
          required TransactionPriority priority}) =>
      SalviumTransactionCreationCredentials(
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
  Object createSalviumTransactionCreationCredentialsRaw(
          {required List<OutputInfo> outputs,
          required TransactionPriority priority}) =>
      SalviumTransactionCreationCredentials(
          outputs: outputs, priority: priority as MoneroTransactionPriority);

  @override
  String formatterSalviumAmountToString({required int amount}) =>
      salviumAmountToString(amount: amount);

  @override
  double formatterSalviumAmountToDouble({required int amount}) =>
      salviumAmountToDouble(amount: amount);

  @override
  int formatterSalviumParseAmount({required String amount}) =>
      salviumParseAmount(amount: amount);

  @override
  Account getCurrentAccount(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    final acc = salviumWallet.walletAddresses.account;
    return Account(id: acc!.id, label: acc.label, balance: acc.balance);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label, String? balance) {
    final salviumWallet = wallet as SalviumWallet;
    salviumWallet.walletAddresses.account =
        salvium_account.Account(id: id, label: label, balance: balance);
  }

  @override
  void onStartup() => salvium_wallet_api.onStartup();

  @override
  int getTransactionInfoAccountId(TransactionInfo tx) {
    final salviumTransactionInfo = tx as SalviumTransactionInfo;
    return salviumTransactionInfo.accountIndex;
  }

  @override
  WalletService createSalviumWalletService(Box<WalletInfo> walletInfoSource,
          Box<UnspentCoinsInfo> unspentCoinSource) =>
      SalviumWalletService(walletInfoSource, unspentCoinSource);

  @override
  String getTransactionAddress(
      Object wallet, int accountIndex, int addressIndex) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.getTransactionAddress(accountIndex, addressIndex);
  }

  @override
  String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.getSubaddressLabel(accountIndex, addressIndex);
  }

  @override
  Map<String, String> pendingTransactionInfo(Object transaction) {
    final ptx = transaction as PendingSalviumTransaction;
    return {'id': ptx.id, 'hex': ptx.hex, 'key': ptx.txKey};
  }

  @override
  List<Unspent> getUnspents(Object wallet) {
    final salviumWallet = wallet as SalviumWallet;
    return salviumWallet.unspentCoins;
  }

  @override
  Future<void> updateUnspents(Object wallet) async {
    final salviumWallet = wallet as SalviumWallet;
    await salviumWallet.updateUnspent();
  }

  @override
  Future<int> getCurrentHeight() async {
    return salvium_wallet_api.getCurrentHeight();
  }

  String getLegacySeed(Object wallet, String langName) =>
      (wallet as SalviumWalletBase).seedLegacy(langName);

  @override
  void salviumcCheck() {
    checkIfMoneroCIsFine();
  }
}
