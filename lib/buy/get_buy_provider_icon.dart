import 'package:flutter/material.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';

Image? getBuyProviderIcon(BuyProviderDescription providerDescription,
   {Color iconColor = Colors.black}) {

  final _wyreIcon =
    Image.asset('assets/images/wyre-icon.png', width: 36, height: 36);
  final _moonPayIcon =
    Image.asset('assets/images/moonpay-icon.png', color: iconColor,
        width: 36, height: 34);

  if (providerDescription != null) {
    switch (providerDescription) {
      case BuyProviderDescription.wyre:
        return _wyreIcon;
      case BuyProviderDescription.moonPay:
        return _moonPayIcon;
      default:
        return null;
    }
  } else {
    return null;
  }
}