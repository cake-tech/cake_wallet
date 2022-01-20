class PickerItem {
  PickerItem({
    this.currencyIndex,
  }) {
    leftIcon = leftIcons[currencyIndex];
  }
  final int currencyIndex;
  String leftIcon;

  List<String> leftIcons = [
    'assets/images/monero.png',
    'assets/images/ada.png',
    'assets/images/bch.png',
    'assets/images/bnb.png',
    'assets/images/bitcoin_icon.png',
    'assets/images/dai_icon.png',
    'assets/images/dash.png',
    'assets/images/eos.png',
    'assets/images/eth.png',
    'assets/images/litecoin_img.png',
    'assets/images/nano.png',
    'assets/images/trx.png',
    'assets/images/usdt.png',
    'assets/images/usdterc_icon.png',
    'assets/images/xlm.png',
    'assets/images/xrp.png',
  ];
}
