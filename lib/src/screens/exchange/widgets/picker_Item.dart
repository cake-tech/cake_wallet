class PickerItem {
  PickerItem({
    this.currencyIndex,
  }) {
    leftIcon = leftIcons[currencyIndex];
    currencyName = currencyNames[currencyIndex];
    pickerTitle = pickerTitles[currencyIndex];
    tagName = getTagTitle(currencyIndex);
  }

  final int currencyIndex;
  String leftIcon;
  String currencyName;
  String pickerTitle;
  String tagName;

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
    'binance bep2',
    'bitcoin',
    'dai eth',
    'dash',
    'eos',
    'ethereum',
    'litecoin',
    'nano',
    'tron',
    'usdt omni',
    'tether ERC20',
    'lumens',
    'ripple',
  ];
  List<String> pickerTitles = [
    'XMR',
    'ADA',
    'BCH',
    'BNB',
    'BTC',
    'DAI',
    'DASH',
    'EOS',
    'ETH',
    'LTC',
    'NANO',
    'TRX',
    'USDT',
    'USDT',
    'XLM',
    'XRP',
  ];

  String getTagTitle(int currencyIndex) {
    switch (currencyIndex) {
      case 3:
        return 'BEP2';
      case 5:
        return 'ETH';
      case 12:
        return 'OMNI';
      case 13:
        return 'ETH';
      default:
        return null;
    }
  }
}
