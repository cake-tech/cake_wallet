import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:flutter/material.dart';

Image getPoweredImage(ExchangeProviderDescription provider) {
    Image image;
    switch (provider) {
      case ExchangeProviderDescription.xmrto:
        image = Image.asset('assets/images/xmrto.png', height: 36, width: 36);
        break;
      case ExchangeProviderDescription.changeNow:
        image = Image.asset('assets/images/changenow.png', height: 36, width: 36);
        break;
      case ExchangeProviderDescription.morphToken:
        image = Image.asset('assets/images/morph.png', height: 36, width: 36);
        break;
      case ExchangeProviderDescription.sideShift:
        image = Image.asset('assets/images/sideshift.png', width: 36, height: 36);
        break;
      default:
        image = null;
    }
    return image;
  }