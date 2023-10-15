part of 'dummy.dart';

class CWDummy extends Dummy {
  @override
  List<String> getDummyWordList() => ["aaa", "bbb", "ccc"];

  @override
  WalletService createDummyWalletService(Box<WalletInfo> walletInfoSource) =>
      DummyWalletService(walletInfoSource);

  @override
  WalletCredentials createDummyNewWalletCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      DummyNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createDummyRestoreWalletFromSeedCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      DummyRestoreWalletFromSeedCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createDummyRestoreWalletFromKeyCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      DummyRestoreWalletFromKeyCredentials(name: name, walletInfo: walletInfo);

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      DummyTransactionPriority.all;

  @override
  TransactionPriority deserializeDummyTransactionPriority(int raw) =>
      DummyTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() =>
      DummyTransactionPriority.fast;

  @override
  CryptoCurrency assetOfTransaction(TransactionInfo tx) {
    final transaction = tx as DummyTransactionInfo;
    // TODO: !!!
    return CryptoCurrency.dummy;
  }

  @override
  String formatterDummyAmountToString({required int amount}) =>
      throw UnimplementedError();

  @override
  TransactionPriority getDummyTransactionPrioritySlow() =>
      DummyTransactionPriority.slow;

  @override
  TransactionPriority getDummyTransactionPriorityMedium() =>
      DummyTransactionPriority.medium;

  @override
  double formatterDummyAmountToDouble({required int amount}) => throw UnimplementedError();

  @override
  int formatterDummyParseAmount({required String amount}) => throw UnimplementedError();

  @override
  Object createDummyTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority}) =>
    DummyTransactionCreationCredentials(outputs: outputs.map((out) => OutputInfo(
      fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount)).toList(), priority: priority as DummyTransactionPriority);

  @override
	Future<void> generateNewAddress(Object wallet) async {
		final dummyWallet = wallet as DummyWallet;
		await dummyWallet.walletAddresses.generateNewAddress();
	}

  @override
  String getAddress(WalletBase wallet) => (wallet as DummyWallet).walletAddresses.address;
}
