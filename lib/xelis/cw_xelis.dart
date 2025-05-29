part of 'xelis.dart';

class CWXelis extends Xelis { 
  @override
  List<String> getXelisWordList(String language) {
    final lang_idx = getLanguageIndexFromStr(input: language);
    return getMnemonicWords(languageIndex: lang_idx);
  }

  WalletService createXelisWalletService(Box<WalletInfo> walletInfoSource, bool isDirect) =>
      XelisWalletService(walletInfoSource, isDirect: isDirect);

  @override
  WalletCredentials createXelisNewWalletCredentials({
    required String name,
    String? mnemonic,
    WalletInfo? walletInfo,
    String? password,
  }) =>
      XelisNewWalletCredentials(
        name: name,
        password: password,
      );

  @override
  WalletCredentials createXelisRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      XelisRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
      );

  @override
  String getAddress(WalletBase wallet) => (wallet as XelisWallet).walletAddresses.address;

  @override
  bool validateAddress(String address) => isAddressValid(strAddress: address);

  @override
  bool isTestnet(Object wallet) {
    final xelisWallet = wallet as XelisWallet;
    return xelisWallet.isTestnet;
  }

  @override
  List<TransactionPriority> getTransactionPriorities() => XelisTransactionPriority.all;

  @override
  TransactionPriority getDefaultTransactionPriority() => XelisTransactionPriority.medium;

  @override
  TransactionPriority getXelisTransactionPriorityFast() => XelisTransactionPriority.fast;

  @override
  TransactionPriority getXelisTransactionPriorityMedium() => XelisTransactionPriority.medium;

  @override
  BigInt getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as XelisTransactionInfo).xelAmount;
  }

  @override
  List<XelisAsset> getXelisAssets(WalletBase wallet) {
    final xelisWallet = wallet as XelisWallet;
    return xelisWallet.xelAssets;
  }

  @override
  TransactionPriority deserializeXelisTransactionPriority(int raw) =>
      XelisTransactionPriority.deserialize(raw: raw);

  @override
  Object createXelisTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
  }) =>
      XelisTransactionCredentials(
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
                memo: out.memo))
            .toList(),
        priority: priority as XelisTransactionPriority,
        currency: currency,
      );

  @override
  Object createXelisTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
  }) =>
      XelisTransactionCredentials(
        outputs,
        priority: priority as XelisTransactionPriority?,
        currency: currency,
      );

  @override
  int formatterStringDoubleToXelisAmount(String amount) => XelisFormatter.parseXelisAmount(amount);

  @override
  double formatterXelisAmountToDouble(
      {TransactionInfo? transaction, BigInt? amount, int decimals = 8}) {
    assert(transaction != null || amount != null);

    if (transaction != null) {
      transaction as XelisTransactionInfo;
      return transaction.xelAmount / BigInt.from(10).pow(decimals);
    } else {
      return amount! / BigInt.from(10).pow(decimals);
    }
  }

  @override
  Future<void> updateAssetState(
    WalletBase wallet,
    CryptoCurrency asset,
    String id,
  ) async {
    final xelAsset = XelisAsset(
      name: asset.name,
      symbol: asset.title,
      id: id,
      decimals: asset.decimals,
      enabled: asset.enabled,
      iconPath: asset.iconPath,
      isPotentialScam: asset.isPotentialScam,
    );

    await (wallet as XelisWallet).updateAssetState(xelAsset);
  }

  @override
  Future<void> removeAssetTransactionsInHistory(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as XelisWallet).removeAssetTransactionsInHistory(token as XelisAsset);

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as XelisTransactionInfo;
    if (transaction.assetIds[0] == xelis_sdk.xelisAsset) {
      if (wallet.isTestnet) {
        return CryptoCurrency.xet;
      }
      return CryptoCurrency.xel;
    }

    wallet as XelisWallet;

    return wallet.xelAssets.firstWhere(
      (element) => transaction.assetIds[0] == element.id,
    );
  }

  @override
  Future<void> deleteAsset(WalletBase wallet, CryptoCurrency asset) async =>
      await (wallet as XelisWallet).deleteAsset(asset as XelisAsset);

  @override
  Future<XelisAsset?> getAsset(WalletBase wallet, String id) async {
    final xelisWallet = wallet as XelisWallet;
    return await xelisWallet.getAsset(id);
  }

  @override
  double? getEstimateFees(WalletBase wallet) {
    return (wallet as XelisWallet).estimatedFee;
  }

  @override
  String getAssetId(CryptoCurrency asset) => (asset as XelisAsset).id;

  @override
  List<String> getDefaultAssetIDs() {
    return [];
  }
}
