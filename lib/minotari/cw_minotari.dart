part of 'minotari.dart';

class CWMinotari extends Minotari {
  @override
  List<String> getMinotariWordList(String language) {
    // Minotari uses standard BIP39 wordlist (24 words)
    // TODO: Import BIP39 wordlist
    return [];
  }

  @override
  WalletService createMinotariWalletService(
    Box<WalletInfo> walletInfoSource,
    Box<UnspentCoinsInfo> unspentCoinsInfoSource,
  ) =>
      MinotariWalletService(walletInfoSource, unspentCoinsInfoSource);

  @override
  WalletCredentials createMinotariNewWalletCredentials({
    required String name,
    String? mnemonic,
    WalletInfo? walletInfo,
  }) =>
      MinotariNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
      );

  @override
  WalletCredentials createMinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required int height,
  }) =>
      MinotariRestoreWalletFromSeedCredentials(
        name: name,
        mnemonic: mnemonic,
        height: height,
      );

  @override
  TransactionPriority getDefaultTransactionPriority() {
    // Minotari doesn't have fee priorities like Bitcoin
    // Using a simple priority enum
    return MinotariTransactionPriority.medium;
  }

  @override
  TransactionPriority getMinotariTransactionPrioritySlow() =>
      MinotariTransactionPriority.slow;

  @override
  TransactionPriority getMinotariTransactionPriorityMedium() =>
      MinotariTransactionPriority.medium;

  @override
  TransactionPriority getMinotariTransactionPriorityFast() =>
      MinotariTransactionPriority.fast;

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      MinotariTransactionPriority.all;

  @override
  String getAddress(WalletBase wallet) =>
      (wallet as MinotariWallet).walletAddresses.address;

  @override
  String? getSeed(WalletBase wallet) => (wallet as MinotariWallet).seed;

  @override
  Object createMinotariTransactionCredentials(
    List<Output> outputs,
  ) =>
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
  int getHeightByDate({required DateTime date}) {
    // TODO: Calculate block height from date
    // For now, return 0 (sync from genesis)
    return 0;
  }

  @override
  Future<int> getCurrentHeight() async {
    // TODO: Get current blockchain height from node
    return 0;
  }

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    final minotariWallet = wallet as MinotariWallet;
    return minotariWallet.transactionHistory;
  }

  @override
  MinotariWallet createMinotariWallet(WalletInfo walletInfo) =>
      MinotariWallet(walletInfo);

  @override
  String getAssetShortName(CryptoCurrency asset) {
    if (asset == CryptoCurrency.xtm) {
      return 'XTM';
    }
    return asset.title;
  }

  @override
  String getAssetFullName(CryptoCurrency asset) {
    if (asset == CryptoCurrency.xtm) {
      return 'Minotari';
    }
    return asset.fullName ?? asset.title;
  }
}
