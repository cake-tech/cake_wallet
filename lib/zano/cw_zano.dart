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

/*class CWZanoWalletDetails extends ZanoWalletDetails {
  CWZanoWalletDetails(this._wallet);

  final Object _wallet;

  // @computed
  // @override
  // Account get account {
  //   final zanoWallet = _wallet as ZanoWallet;
  //   final acc = zanoWallet.walletAddresses.account as monero_account.Account;
  //   return Account(id: acc.id, label: acc.label);
  // }

  // @computed
  // @override
  // ZanoBalance get balance {
  //   final zanoWallet = _wallet as ZanoWallet;
  //   final balance = zanoWallet.balance;
  //   return ZanoBalance(fullBalance: balance[CryptoCurrency.zano]!.total, unlockedBalance: balance[CryptoCurrency.zano]!.unlocked);
  // }
}*/

class CWZano extends Zano {
  /**@override
  ZanoAccountList getAccountList(Object wallet) {
    return CWZanoAccountList(wallet);
  }*/

  List<ZanoAsset> getZanoAssets(WalletBase wallet) {
    wallet as ZanoWallet;
    return wallet.zanoAssets;
  }

  @override
  Future<CryptoCurrency> addZanoAssetById(WalletBase wallet, String assetId) async => await (wallet as ZanoWallet).addZanoAssetById(assetId);

  @override
  Future<void> changeZanoAssetAvailability(WalletBase wallet, CryptoCurrency token) async => await (wallet as ZanoWallet).changeZanoAssetAvailability(token as ZanoAsset);

  @override
  Future<void> deleteZanoAsset(WalletBase wallet, CryptoCurrency token) async => await (wallet as ZanoWallet).deleteZanoAsset(token as ZanoAsset);

  @override
  Future<ZanoAsset?> getZanoAsset(WalletBase wallet, String assetId) async {
    final zanoWallet = wallet as ZanoWallet;
    return await zanoWallet.getZanoAsset(assetId);
  }

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final zanoWallet = wallet as ZanoWallet;
    return zanoWallet.transactionHistory;
  }

  // @override
  // ZanoWalletDetails getZanoWalletDetails(Object wallet) {
  //   return CWZanoWalletDetails(wallet);
  // }

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
        name: name, spendKey: spendKey, viewKey: viewKey, address: address, password: password, language: language, height: height);
  }

  @override
  WalletCredentials createZanoRestoreWalletFromSeedCredentials(
      {required String name, required String password, required int height, required String mnemonic}) {
    return ZanoRestoreWalletFromSeedCredentials(name: name, password: password, height: height, mnemonic: mnemonic);
  }

  @override
  WalletCredentials createZanoNewWalletCredentials({required String name, String? password}) {
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
  Object createZanoTransactionCredentials({required List<Output> outputs, required TransactionPriority priority, required CryptoCurrency currency}) {
    return ZanoTransactionCredentials(
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
      currency: currency,
    );
  }

  @override
  double formatterIntAmountToDouble({required int amount, required CryptoCurrency currency}) {
    if (currency is ZanoAsset) return ZanoFormatter.intAmountToDouble(amount, currency.decimalPoint);
    return ZanoFormatter.intAmountToDouble(amount);
  }

  @override
  int formatterParseAmount({required String amount, required CryptoCurrency currency}) {
    if (currency is ZanoAsset) return ZanoFormatter.parseAmount(amount, currency.decimalPoint);
    return ZanoFormatter.parseAmount(amount);
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

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as ZanoTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.zano.title) {
      return CryptoCurrency.zano;
    }
    wallet as ZanoWallet;
    return wallet.zanoAssets.firstWhere((element) => element.ticker == transaction.tokenSymbol);
  }

  String getZanoAssetAddress(CryptoCurrency asset) => (asset as ZanoAsset).assetId;

  @override
  String getAddress(WalletBase wallet) => (wallet as ZanoWallet).walletAddresses.address;
}
