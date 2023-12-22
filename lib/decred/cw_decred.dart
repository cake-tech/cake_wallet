part of 'decred.dart';

class CWDecred extends Decred {
  @override
  TransactionPriority getMediumTransactionPriority() =>
      DecredTransactionPriority.medium;

  @override
  WalletCredentials createDecredRestoreWalletFromSeedCredentials(
          {required String name,
          required String mnemonic,
          required String password}) =>
      DecredRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password);

  @override
  WalletCredentials createDecredNewWalletCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      DecredNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  List<String> getWordList() => wordList();

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      DecredTransactionPriority.all;

  @override
  TransactionPriority deserializeDecredTransactionPriority(int raw) =>
      DecredTransactionPriority.deserialize(raw: raw);

  @override
  int getFeeRate(Object wallet, TransactionPriority priority) {
    final decredWallet = wallet as DecredWallet;
    return decredWallet.feeRate(priority);
  }

  @override
  Future<void> generateNewAddress(Object wallet) async {
    final decredWallet = wallet as DecredWallet;
    await decredWallet.walletAddresses.generateNewAddress();
  }

  @override
  Object createDecredTransactionCredentials(
          List<Output> outputs, TransactionPriority priority) =>
      DecredTransactionCredentials(
          outputs
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
          priority:
              priority != null ? priority as DecredTransactionPriority : null);

  @override
  List<String> getAddresses(Object wallet) {
    final decredWallet = wallet as DecredWallet;
    return decredWallet.walletAddresses.addresses();
  }

  @override
  String getAddress(Object wallet) {
    final decredWallet = wallet as DecredWallet;
    return decredWallet.walletAddresses.address;
  }

  @override
  String formatterDecredAmountToString({required int amount}) =>
      decredAmountToString(amount: amount);

  @override
  double formatterDecredAmountToDouble({required int amount}) =>
      decredAmountToDouble(amount: amount);

  @override
  int formatterStringDoubleToDecredAmount(String amount) =>
      stringDoubleToDecredAmount(amount);

  @override
  List<Unspent> getUnspents(Object wallet) {
    final decredWallet = wallet as DecredWallet;
    return decredWallet.unspents();
  }

  void updateUnspents(Object wallet) async {}

  WalletService createDecredWalletService(Box<WalletInfo> walletInfoSource) {
    return DecredWalletService(walletInfoSource);
  }

  @override
  TransactionPriority getDecredTransactionPriorityMedium() =>
      DecredTransactionPriority.medium;

  @override
  TransactionPriority getDecredTransactionPrioritySlow() =>
      DecredTransactionPriority.slow;
}
