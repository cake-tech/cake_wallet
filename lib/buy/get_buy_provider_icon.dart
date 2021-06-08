import 'package:flutter/material.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';

Image getBuyProviderIcon(BuyProviderDescription providerDescription,
   {bool isWhiteIconColor = false}) {

  final _wyreIcon =
    Image.asset('assets/images/wyre-icon.png', width: 36, height: 36);
  final _moonPayWhiteIcon =
    Image.asset('assets/images/moonpay-icon.png', color: Colors.white,
        width: 36, height: 34);
  final _moonPayBlackIcon =
  Image.asset('assets/images/moonpay-icon.png', color: Colors.black,
      width: 36, height: 34);

  if (providerDescription != null) {
    switch (providerDescription) {
      case BuyProviderDescription.wyre:
        return _wyreIcon;
      case BuyProviderDescription.moonPay:
        return isWhiteIconColor ? _moonPayWhiteIcon : _moonPayBlackIcon;
      default:
        return null;
    }
  } else {
    return null;
  }
}