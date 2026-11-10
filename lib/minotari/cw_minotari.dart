part of 'minotari.dart';

class CWMinotari extends Minotari {
  @override
  WalletService createMinotariWalletService() => MinotariWalletService();

  @override
  WalletCredentials createMinotariNewWalletCredentials({
    required String name,
    String? password,
    WalletInfo? walletInfo,
  }) =>
      MinotariNewWalletCredentials(
        name: name,
        password: password,
        walletInfo: walletInfo,
      );

  @override
  WalletCredentials createMinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    required int height,
    WalletInfo? walletInfo,
  }) =>
      MinotariRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        height: height,
        walletInfo: walletInfo,
      );

  @override
  WalletCredentials createMinotariRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required String viewPrivateKeyHex,
    String? spendPrivateKeyHex,
    String? spendPublicKeyHex,
    required int height,
    WalletInfo? walletInfo,
  }) =>
      MinotariRestoreWalletFromKeysCredentials(
        name: name,
        password: password,
        viewPrivateKeyHex: viewPrivateKeyHex,
        spendPrivateKeyHex: spendPrivateKeyHex,
        spendPublicKeyHex: spendPublicKeyHex,
        height: height,
        walletInfo: walletInfo,
      );

  @override
  List<TransactionPriority> getTransactionPriorities() => MinotariTransactionPriority.all;

  @override
  TransactionPriority deserializeMinotariTransactionPriority({required int raw}) =>
      MinotariTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getMinotariTransactionPriorityMedium() => MinotariTransactionPriority.medium;

  @override
  TransactionPriority getMinotariTransactionPrioritySlow() => MinotariTransactionPriority.slow;

  @override
  Object createMinotariTransactionCredentials(List<Output> outputs,
          {TransactionPriority? priority}) =>
      MinotariTransactionCredentials(
        outputs
            .map((out) => OutputInfo(
                  fiatAmount: out.fiatAmount,
                  cryptoAmount: out.cryptoAmountMoney,
                  address: out.address,
                  note: out.note,
                  sendAll: out.sendAll,
                  extractedAddress: out.extractedAddress,
                  isParsedAddress: out.isParsedAddress,
                ))
            .toList(),
        priority: priority,
      );

  @override
  Object createMinotariTransactionCredentialsRaw(List<OutputInfo> outputs) =>
      MinotariTransactionCredentials(outputs);

  @override
  Future<int> getHeightByDate({required DateTime date}) => minotariHeightByDate(date);

  @override
  Future<int> getCurrentHeight(Object wallet) => (wallet as MinotariWallet).currentHeight();

  @override
  Future<String?> getSeed(Object wallet) => (wallet as MinotariWallet).loadSeed();

  @override
  Map<String, String> getKeys(Object wallet) {
    final minotariWallet = wallet as MinotariWallet;
    return {
      if (minotariWallet.viewPrivateKeyHex != null)
        'privateViewKey': minotariWallet.viewPrivateKeyHex!,
      if (minotariWallet.spendPublicKeyHex != null)
        'publicSpendKey': minotariWallet.spendPublicKeyHex!,
    };
  }

  @override
  Future<void> checkpointDatabase() => MinotariWalletService.checkpointDatabase();

  @override
  int? getRestoreHeight(Object wallet) => (wallet as MinotariWallet).walletInfo.restoreHeight;
}
