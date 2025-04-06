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
    required String password,
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
  List<TransactionPriority> getTransactionPriorities() => XelisTransactionPriority.all;

  @override
  TransactionPriority getDefaultTransactionPriority() => XelisTransactionPriority.slow;

  @override
  TransactionPriority getXelisTransactionPriorityFast() => XelisTransactionPriority.fast;

  @override
  TransactionPriority getXelisTransactionPriorityMedium() => XelisTransactionPriority.medium;

  @override
  TransactionPriority getXelisTransactionPrioritySlow() => XelisTransactionPriority.slow;

  @override
  BigInt getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as XelisTransactionInfo).xelAmount;
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
      return transaction.xelAmount / BigInt.from(10).pow(transaction.decimals);
    } else {
      return amount! / BigInt.from(10).pow(decimals);
    }
  }

  @override
  List<String> getDefaultAssetIDs() {
    return [];
  }
}
