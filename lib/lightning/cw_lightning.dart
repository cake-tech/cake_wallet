part of 'lightning.dart';

class CWLightning extends Lightning {
  @override
  WalletCredentials createLightningRestoreWalletFromSeedCredentials(
          {required String name, required String mnemonic, required String password}) =>
      BitcoinRestoreWalletFromSeedCredentials(name: name, mnemonic: mnemonic, password: password);

  @override
  WalletCredentials createLightningRestoreWalletFromWIFCredentials(
          {required String name,
          required String password,
          required String wif,
          WalletInfo? walletInfo}) =>
      BitcoinRestoreWalletFromWIFCredentials(
          name: name, password: password, wif: wif, walletInfo: walletInfo);

  @override
  WalletCredentials createLightningNewWalletCredentials(
          {required String name, WalletInfo? walletInfo}) =>
      BitcoinNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  Object createLightningTransactionCredentials(List<Output> outputs,
          {required TransactionPriority priority, int? feeRate}) =>
      BitcoinTransactionCredentials(
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
          priority: priority as BitcoinTransactionPriority,
          feeRate: feeRate);

  @override
  Object createLightningTransactionCredentialsRaw(List<OutputInfo> outputs,
          {TransactionPriority? priority, required int feeRate}) =>
      BitcoinTransactionCredentials(outputs,
          priority: priority != null ? priority as BitcoinTransactionPriority : null,
          feeRate: feeRate);

  @override
  String formatterLightningAmountToString({required int amount}) =>
      bitcoinAmountToString(amount: amount * 100000000);

  @override
  double formatterLightningAmountToDouble({required int amount}) =>
      bitcoinAmountToDouble(amount: amount * 100000000);

  @override
  int formatterStringDoubleToLightningAmount(String amount) =>
      stringDoubleToBitcoinAmount(amount * 100000000);

  WalletService createLightningWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return LightningWalletService(walletInfoSource, unspentCoinSource);
  }

  @override
  List<LightningReceivePageOption> getLightningReceivePageOptions() =>
      LightningReceivePageOption.all;

  @override
  ReceivePageOption getOptionInvoice() => LightningReceivePageOption.lightningInvoice;

  @override
  ReceivePageOption getOptionOnchain() => LightningReceivePageOption.lightningOnchain;

  String satsToLightningString(int sats) {
    const bitcoinAmountLength = 8;
    const bitcoinAmountDivider = 100000000;
    const lightningAmountDivider = 1;
    final bitcoinAmountFormat = NumberFormat()
      ..maximumFractionDigits = bitcoinAmountLength
      ..minimumFractionDigits = 1;

    String formattedAmount = bitcoinAmountFormat.format(sats);
    return formattedAmount.substring(0, formattedAmount.length - 2);
  }

  String bitcoinAmountToLightningString({required int amount}) {
    final bitcoinAmountFormat = NumberFormat()
      ..maximumFractionDigits = bitcoinAmountLength
      ..minimumFractionDigits = 1;
    String formattedAmount = bitcoinAmountFormat
        .format(cryptoAmountToDouble(amount: amount, divider: 1));
    return formattedAmount.substring(0, formattedAmount.length - 2);
  }

  int bitcoinAmountToLightningAmount({required int amount}) {
    return amount * 100000000;
  }
}
