part of 'decred.dart';

class CWDecred extends Decred {
  CWDecred() {
    // initialize the service for creating and loading dcr wallets.
    DecredWalletService.init();
  }

  @override
  WalletCredentials createDecredNewWalletCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      DecredNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createDecredRestoreWalletFromSeedCredentials(
          {required String name,
          required String mnemonic,
          required String password}) =>
      DecredRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password);

  WalletService createDecredWalletService(Box<WalletInfo> walletInfoSource) {
    return DecredWalletService(walletInfoSource);
  }

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      DecredTransactionPriority.all;

  @override
  TransactionPriority getMediumTransactionPriority() =>
      DecredTransactionPriority.medium;

  @override
  TransactionPriority getDecredTransactionPriorityMedium() =>
      DecredTransactionPriority.medium;

  @override
  TransactionPriority getDecredTransactionPrioritySlow() =>
      DecredTransactionPriority.slow;

  @override
  TransactionPriority deserializeDecredTransactionPriority(int raw) =>
      DecredTransactionPriority.deserialize(raw: raw);

  @override
  int getFeeRate(Object wallet, TransactionPriority priority) {
    final decredWallet = wallet as DecredWallet;
    return decredWallet.feeRate(priority);
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
          priority: priority as DecredTransactionPriority);

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
  Future<void> generateNewAddress(Object wallet) async {
    final decredWallet = wallet as DecredWallet;
    await decredWallet.walletAddresses.generateNewAddress();
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
}
