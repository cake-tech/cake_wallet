part of 'lightning.dart';

class CWLightning extends Lightning {

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

  @override
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

  @override
  String bitcoinAmountToLightningString({required int amount}) {
    final bitcoinAmountFormat = NumberFormat()
      ..maximumFractionDigits = bitcoinAmountLength
      ..minimumFractionDigits = 1;
    String formattedAmount =
        bitcoinAmountFormat.format(cryptoAmountToDouble(amount: amount, divider: 1));
    return formattedAmount.substring(0, formattedAmount.length - 2);
  }

  @override
  int bitcoinAmountToLightningAmount({required int amount}) {
    return amount * 100000000;
  }

  @override
  double bitcoinDoubleToLightningDouble({required double amount}) {
    return amount * 100000000;
  }

  @override
  double lightningDoubleToBitcoinDouble({required double amount}) {
    return amount / 100000000;
  }
}
