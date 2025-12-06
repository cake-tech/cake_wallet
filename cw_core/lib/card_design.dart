import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

enum CardDesignBackgroundTypes { image, svgIcon, svgFull }

class CardColorCombination {
  final Color textColor;
  final Color textColorSecondary;
  final Color backgroundImageColor;

  const CardColorCombination(
      {required this.textColor,
      required this.textColorSecondary,
      required this.backgroundImageColor});

  static const light = CardColorCombination(
    textColor: Colors.white,
    textColorSecondary: Colors.white54,
    backgroundImageColor: Color(0x66FFFFFF),
  );

  static const dark = CardColorCombination(
    textColor: Colors.black,
    textColorSecondary: Colors.black45,
    backgroundImageColor: Color(0x44FFFFFF),
  );
}

class CardDesign {
  final Gradient gradient;
  final String imagePath;
  final CardDesignBackgroundTypes backgroundType;
  final CardColorCombination colors;

  const CardDesign(
      {this.backgroundType = CardDesignBackgroundTypes.svgIcon,
      this.gradient = const LinearGradient(colors: [Colors.black]),
      this.imagePath = "assets/new-ui/blank.svg",
      this.colors = CardColorCombination.dark});

  static const LinearGradient gradientOrange = LinearGradient(
    colors: <Color>[Color(0xFFFF7C02), Color(0xFFFF5602)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientYellow = LinearGradient(
    colors: <Color>[Color(0xFFFFD000), Color(0xFFFFAA00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient gradientGreen = LinearGradient(
    colors: <Color>[Color(0xFF5AA438), Color(0xFF5AA438)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientBlue = LinearGradient(
    colors: <Color>[Colors.lightBlue, Colors.blue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientPurple = LinearGradient(
    colors: <Color>[Color(0xFF9E30FF), Color(0xFF7100BD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientPink = LinearGradient(
    colors: <Color>[Color(0xFFFF6CD3), Color(0xFFF200A9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientRed = LinearGradient(
    colors: <Color>[Color(0xFFFF2222), Color(0xFFA10000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientSilver = LinearGradient(
    colors: <Color>[Color(0xFFE0E8FF), Color(0xFF6D8ADE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientGold = LinearGradient(
    colors: <Color>[Color(0xFFE9CA74), Color(0xFF886A14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradientBlack = LinearGradient(
    colors: <Color>[Color(0xFF2A2A2A), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const List<Gradient> allGradients = <Gradient>[
    gradientOrange,
    gradientYellow,
    gradientGreen,
    gradientBlue,
    gradientPurple,
    gradientPink,
    gradientRed,
    gradientSilver,
    gradientGold,
    gradientBlack,
  ];

  static const genericDefault = CardDesign(gradient: gradientBlue);
  static const btc = CardDesign(
      gradient: gradientYellow, imagePath: "assets/new-ui/balance_card_icons/bitcoin.svg");

  static const eth = CardDesign(
      gradient: gradientPurple,
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_icons/ethereum.svg");

  static const btcln = CardDesign(
      gradient: gradientSilver, imagePath: "assets/new-ui/balance_card_icons/lightning.svg");

  static const ethSpecial = CardDesign(
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF6259FF), Color(0xFF3B20E6)],
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/ethereum.svg");

  CardDesign withGradient(Gradient gradient) => CardDesign(
      gradient: gradient, colors: colors, imagePath: imagePath, backgroundType: backgroundType);

  static const List<CardDesign> all = [genericDefault, btc, eth, btcln, ethSpecial];

  static CardDesign forCurrency(CryptoCurrency currency) {
    return defaultDesignsForCurrencies[currency] ?? genericDefault;
  }

  static CardDesign forCurrencySpecial(CryptoCurrency currency) {
    return specialDesignsForCurrencies[currency] ?? genericDefault;
  }

  static const Map<CryptoCurrency, CardDesign> defaultDesignsForCurrencies = {
    CryptoCurrency.btc: btc,
    CryptoCurrency.eth: eth,
    CryptoCurrency.btcln: btcln,
  };

  static const Map<CryptoCurrency, CardDesign> specialDesignsForCurrencies = {
    CryptoCurrency.eth: ethSpecial,
  };
}
