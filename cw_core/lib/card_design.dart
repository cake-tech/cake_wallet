import 'package:cw_core/balance_card_style_settings.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
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
      this.gradient = const LinearGradient(colors: [Colors.black], begin: Alignment.topCenter, end: Alignment.bottomCenter),
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
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/ethereum.svg");

  static const btcSpecial = CardDesign(
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFFFFBF00), Color(0xFFFF6A00)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/bitcoin.svg");

  static const xmrSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF5900), Color(0xFFE62E00)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/monero.svg");

  static const ltcSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2145BF), Color(0xFF072071)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/litecoin.svg");

  static const lnSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFBF00), Color(0xFFFF6A00)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_backgrounds/lightning.svg");

  static const tronSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF1313), Color(0xFFB40000)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_backgrounds/tron.svg");

  static const solSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF4701AA), Color(0xFF19004B)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_backgrounds/solana.svg");

  static const bchSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF36DA4C), Color(0xFF008D57)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/bitcoincash.svg");

  static const wowSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF6CD3), Color(0xFFF200A9)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/wownero.svg");

  static const dogeSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFCBA818), Color(0xFF885D00)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/dogecoin.svg");

  static const nanoSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF209CE9), Color(0xFF0073CB)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/nano.svg");

  CardDesign withGradient(Gradient gradient) => CardDesign(
      gradient: gradient, colors: preferredColorCombinations[gradient] ?? colors, imagePath: imagePath, backgroundType: backgroundType);

  static const List<CardDesign> all = [genericDefault, btc, eth, btcln, ethSpecial, btcSpecial, xmrSpecial, ltcSpecial, lnSpecial, tronSpecial, bchSpecial, wowSpecial, dogeSpecial];

  static CardDesign forCurrency(CryptoCurrency currency) {
    return defaultDesignsForCurrencies[currency] ?? genericDefault;
  }

  static CardDesign forCurrencySpecial(CryptoCurrency currency) {
    return specialDesignsForCurrencies[currency] ?? genericDefault;
  }

  static const Map<CryptoCurrency, CardDesign> defaultDesignsForCurrencies = {
    CryptoCurrency.btc: btc,
    CryptoCurrency.eth: eth,
  };

  static const Map<CryptoCurrency, CardDesign> specialDesignsForCurrencies = {
    CryptoCurrency.xmr: xmrSpecial,
    CryptoCurrency.btc: btcSpecial,
    CryptoCurrency.eth: ethSpecial,
    CryptoCurrency.ltc: ltcSpecial,
    CryptoCurrency.btcln: lnSpecial,
    CryptoCurrency.trx: tronSpecial,
    CryptoCurrency.sol: solSpecial,
    CryptoCurrency.bch: bchSpecial,
    CryptoCurrency.wow: wowSpecial,
    CryptoCurrency.doge: dogeSpecial,
    CryptoCurrency.nano: nanoSpecial,
  };

  static Map<Gradient, CardColorCombination> preferredColorCombinations = {
    CardDesign.gradientOrange: CardColorCombination.light,
    CardDesign.gradientYellow: CardColorCombination.dark,
    CardDesign.gradientGreen: CardColorCombination.light,
    CardDesign.gradientBlue: CardColorCombination.dark,
    CardDesign.gradientPurple: CardColorCombination.light,
    CardDesign.gradientPink: CardColorCombination.dark,
    CardDesign.gradientRed: CardColorCombination.light,
    CardDesign.gradientSilver: CardColorCombination.dark,
    CardDesign.gradientGold: CardColorCombination.dark,
    CardDesign.gradientBlack: CardColorCombination.light,
  };

  static CardDesign fromStyleSettings(
      BalanceCardStyleSettings? setting, CryptoCurrency walletCurrency) {
    if (setting == null) {
      return CardDesign.forCurrency(walletCurrency);
    } else if (setting.backgroundImagePath.isNotEmpty) {
      return CardDesign(
        imagePath: setting.backgroundImagePath,
      );
    } else if (setting.useSpecialDesign && setting.gradientIndex != -1) {
      return CardDesign.forCurrencySpecial(walletCurrency)
          .withGradient(CardDesign.allGradients[setting.gradientIndex]);
    } else if (setting.useSpecialDesign) {
      return CardDesign.forCurrencySpecial(walletCurrency);
    } else if (setting.gradientIndex != -1) {
      return CardDesign.forCurrency(walletCurrency)
          .withGradient(CardDesign.allGradients[setting.gradientIndex]);
    } else {
      printV("somehow, the user saved the design settings with literally no customization?");
      return CardDesign.forCurrency(walletCurrency);
    }
  }
}
