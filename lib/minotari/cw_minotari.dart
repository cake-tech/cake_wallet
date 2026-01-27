part of 'minotari.dart';

class CWMinotari extends Minotari {
  @override
  WalletService createMinotariWalletService() => MinotariWalletService();

  @override
  WalletCredentials createMinotariNewWalletCredentials({
    required String name,
    String? password,
    String? passphrase,
    WalletInfo? walletInfo,
  }) =>
      MinotariNewWalletCredentials(
        name: name,
        password: password,
        passphrase: passphrase,
        walletInfo: walletInfo,
      );

  @override
  WalletCredentials createMinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    required int height,
    String? passphrase,
    WalletInfo? walletInfo,
  }) =>
      MinotariRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        height: height,
        passphrase: passphrase,
        walletInfo: walletInfo,
      );

  @override
  double? getMinotariEstimatedFee(Object wallet) {
    // TODO: Use FFI estimateFee() when implemented to get accurate fee estimate.
    const double placeholderFee = 26666;
    return placeholderFee;
  }

  @override
  Object createMinotariTransactionCredentials(List<Output> outputs) =>
      MinotariTransactionCredentials(
        outputs.map((out) => OutputInfo(
          fiatAmount: out.fiatAmount,
          cryptoAmount: out.cryptoAmount,
          address: out.address,
          note: out.note,
          sendAll: out.sendAll,
          extractedAddress: out.extractedAddress,
          isParsedAddress: out.isParsedAddress,
          formattedCryptoAmount: out.formattedCryptoAmount,
        )).toList(),
      );

  @override
  Object createMinotariTransactionCredentialsRaw(List<OutputInfo> outputs) =>
      MinotariTransactionCredentials(outputs);

  @override
  int getHeightByDate({required DateTime date}) {
    // TODO: Implement proper block height calculation from date
    return 0;
  }

  @override
  Future<int> getCurrentHeight() async {
    // TODO: Get current blockchain height from connected node
    return 0;
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final minotariWallet = wallet as MinotariWallet;
    final keys = <String, String>{};

    final seed = minotariWallet.seed;
    if (seed != null) {
      keys['seed'] = seed;
    }

    // TODO: Add view key, spend key if Minotari exposes them
    // keys['privateSpendKey'] = ...;
    // keys['publicSpendKey'] = ...;

    return keys;
  }

  @override
  int? getRestoreHeight(Object wallet) {
    final minotariWallet = wallet as MinotariWallet;
    // Return the wallet's restore height from walletInfo
    return minotariWallet.walletInfo.restoreHeight;
  }

  @override
  String formatterMinotariAmountToString({required int amount}) =>
      minotariAmountToString(amount: amount);

  @override
  double formatterMinotariAmountToDouble({required int amount}) =>
      minotariAmountToDouble(amount: amount);

  @override
  int formatterMinotariParseAmount({required String amount}) =>
      minotariParseAmount(amount: amount);
}
