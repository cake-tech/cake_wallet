class PickerItem {
  PickerItem({
    this.currencyIndex,
  }) {
    leftIcon = leftIcons[currencyIndex];
    currencyName = currencyNames[currencyIndex];
  }
  final int currencyIndex;
  String leftIcon;
  String currencyName;

  List<String> leftIcons = [
    'assets/images/monero_icon.png',
    'assets/images/ada_icon.png',
    'assets/images/bch_icon.png',
    'assets/images/bnb_icon.png',
    'assets/images/btc.png',
    'assets/images/dai_icon.png',
    'assets/images/dash_icon.png',
    'assets/images/eos_icon.png',
    'assets/images/eth_icon.png',
    'assets/images/litecoin-ltc_icon.png',
    'assets/images/nano.png',
    'assets/images/trx_icon.png',
    'assets/images/usdt_icon.png',
    'assets/images/usdterc20_icon.png',
    'assets/images/xlm_icon.png',
    'assets/images/xrp_icon.png',
  ];

  List<String> currencyNames = [
    'monero',
    'cardano',
    'bitcoin cash',
    'binance',
    'bitcoin',
    'dai',
    'dash',
    'eos',
    'ethereum',
    'litecoin',
    'nano',
    'tron',
    'tether',
    'tether ERC20',
    'lumens',
    'ripple',
  ];
}
