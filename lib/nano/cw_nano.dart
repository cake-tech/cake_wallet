part of 'nano.dart';

class CWNanoAccountList extends NanoAccountList {
  CWNanoAccountList(this._wallet);
  final Object _wallet;

  @override
  @computed
  ObservableList<NanoAccount> get accounts {
    final nanoWallet = _wallet as NanoWallet;
    final accounts = nanoWallet.walletAddresses.accountList.accounts
        .map((acc) => NanoAccount(id: acc.id, label: acc.label, balance: acc.balance))
        .toList();
    return ObservableList<NanoAccount>.of(accounts);
  }

  @override
  void update(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    nanoWallet.walletAddresses.accountList.update(null);
  }

  @override
  void refresh(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    nanoWallet.walletAddresses.accountList.refresh();
  }

  @override
  Future<List<NanoAccount>> getAll(Object wallet) async {
    final nanoWallet = wallet as NanoWallet;
    return (await nanoWallet.walletAddresses.accountList.getAll())
        .map((acc) => NanoAccount(id: acc.id, label: acc.label, balance: acc.balance))
        .toList();
  }

  @override
  Future<void> addAccount(Object wallet, {required String label}) async {
    final nanoWallet = wallet as NanoWallet;
    await nanoWallet.walletAddresses.accountList.addAccount(label: label);
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final nanoWallet = wallet as NanoWallet;
    await nanoWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}

class CWNano extends Nano {
  @override
  NanoAccountList getAccountList(Object wallet) {
    return CWNanoAccountList(wallet);
  }

  @override
  Account getCurrentAccount(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    final acc = nanoWallet.walletAddresses.account;
    return Account(id: acc!.id, label: acc.label, balance: acc.balance);
  }

  @override
  void setCurrentAccount(Object wallet, int id, String label, String? balance) {
    final nanoWallet = wallet as NanoWallet;
    nanoWallet.walletAddresses.account = NanoAccount(id: id, label: label, balance: balance);
    nanoWallet.regenerateAddress();
  }

  @override
  List<String> getNanoWordList(String language) {
    return NanoMnemomics.WORDLIST;
  }

  @override
  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource) {
    return NanoWalletService(walletInfoSource);
  }

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    throw UnimplementedError();
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    final keys = nanoWallet.keys;
    return <String, String>{
      "seedKey": keys.seedKey,
    };
  }

  @override
  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String? password,
  }) =>
      NanoNewWalletCredentials(
        name: name,
        password: password,
      );

  @override
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    DerivationType? derivationType,
  }) {

    if (derivationType == null) {
      // figure out the derivation type as best we can, otherwise set it to "unknown"
      if (mnemonic.split(" ").length == 12) {
        derivationType = DerivationType.bip39;
      } else {
        derivationType = DerivationType.unknown;
      }
    }

    return NanoRestoreWalletFromSeedCredentials(
      name: name,
      password: password,
      mnemonic: mnemonic,
      derivationType: derivationType,
    );
  }

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    throw UnimplementedError();
  }

  @override
  void onStartup() {}

  @override
  Object createNanoTransactionCredentials(List<Output> outputs) {
    return NanoTransactionCredentials(
      outputs
          .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount,
              ))
          .toList(),
    );
  }

  @override
  Future<void> setLabelAccount(Object wallet,
      {required int accountIndex, required String label}) async {
    final nanoWallet = wallet as NanoWallet;
    await nanoWallet.walletAddresses.accountList
        .setLabelAccount(accountIndex: accountIndex, label: label);
  }
}
