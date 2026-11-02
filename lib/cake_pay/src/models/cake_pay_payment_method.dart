enum CakePayPaymentMethod { BTC, BTC_LN, XMR, LTC, LTC_MWEB, ZEC, USDC, USDT }

extension CakePayPaymentMethodLabel on CakePayPaymentMethod {
  String get label => switch (this) {
        CakePayPaymentMethod.BTC => "Bitcoin",
        CakePayPaymentMethod.BTC_LN => "Lightning",
        CakePayPaymentMethod.XMR => "Monero",
        CakePayPaymentMethod.LTC => "Litecoin",
        CakePayPaymentMethod.LTC_MWEB => "MWEB",
        CakePayPaymentMethod.ZEC => "Zcash",
        CakePayPaymentMethod.USDC || CakePayPaymentMethod.USDT => name,
      };
}
