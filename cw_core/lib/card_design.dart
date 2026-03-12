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
      textColor: Color.fromARGB(200, 255, 255, 255),
      textColorSecondary: Colors.white54,
      backgroundImageColor: Color.fromARGB(200, 0, 0, 0)
  );

  static const dark = CardColorCombination(
    textColor: Color.fromARGB(200, 0, 0, 0),
    textColorSecondary: Colors.black45,
    backgroundImageColor: Color.fromARGB(200, 255, 255, 255),
  );

  static const black = CardColorCombination(
    textColor: Color.fromARGB(200, 255, 255, 255),
    textColorSecondary: Colors.white54,
    backgroundImageColor: Color.fromARGB(200, 255, 255, 255),
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
    colors: <Color>[Color(0xFF4EBEFF), Color(0xFF1D78FF)],
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
      imagePath: "assets/new-ui/balance_card_icons/bitcoin.svg");

  static const eth = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/ethereum.svg");

  static const btcln = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/lightning.svg");

  static const xmr = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/monero.svg");

  static const ltc = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/litecoin.svg");

  static const bch = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/bitcoin_cash.svg");

  static const doge = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/dogecoin.svg");

  static const base = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/base.svg");

  static const pol = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/polygon.svg");

  static const sol = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/solana.svg");

  static const tron = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/tron.svg");

  static const nano = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/nano.svg");

  static const zano = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/zano.svg");

  static const wow = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/wownero.svg");

  static const dcr = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/decred.svg");

  static const arbitrum = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/arbitrum.svg");

  static const zec = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/zcash.svg");

  static const bnb = CardDesign(
      imagePath: "assets/new-ui/balance_card_icons/bnb.svg");



  static const ethSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6259FF), Color(0xFF3B20E6)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      colors: CardColorCombination.light,
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
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_backgrounds/litecoin.svg");

  static const lnSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFBF00), Color(0xFFFF6A00)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      colors: CardColorCombination.dark,
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
      imagePath: "assets/new-ui/balance_card_backgrounds/bitcoin-cash.svg");

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

  static const polSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF863FE3), Color(0xFF59098E)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_backgrounds/polygon.svg");

  static const dcrSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2871FF), Color(0xFF0057FF)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      colors: CardColorCombination.light,
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/decred.svg");

  static const zanoSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0004B4), Color(0xFF170069)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      colors: CardColorCombination.black,
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/zano.svg");

  static const baseSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF003CFF), Color(0xFF000087)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      colors: CardColorCombination.light,
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/base.svg");

  static const arbitrumSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF173F76), Color(0xFF031A39)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      colors: CardColorCombination.light,
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/arbitrum.svg");

  static const zecSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF6C527), Color(0xFFCD8C00)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/zcash.svg");

  static const bnbSpecial = CardDesign(
      gradient: const LinearGradient(
          colors: <Color>[Color(0xFF603000), Color(0xFFF0B90B)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter
      ),
      colors: CardColorCombination.light,
      backgroundType: CardDesignBackgroundTypes.svgFull,
      imagePath: "assets/new-ui/balance_card_backgrounds/bnb.svg");

  CardDesign withGradient(Gradient gradient) => CardDesign(
      gradient: gradient, colors: preferredColorCombinations[gradient] ?? colors, imagePath: imagePath, backgroundType: backgroundType);

  CardDesign withGradientAndColorCombination(Gradient gradient, CardColorCombination cardColorCombination) => CardDesign(
      gradient: gradient, colors: cardColorCombination, imagePath: imagePath, backgroundType: backgroundType);

  static const List<CardDesign> all = [genericDefault, btc, eth, xmr, ltc, eth, pol, doge, base, sol, btcln, tron, zano, dcr, arbitrum, zec, bnb, ethSpecial, btcSpecial, xmrSpecial, ltcSpecial, lnSpecial, tronSpecial, bchSpecial, wowSpecial, dogeSpecial, polSpecial, dcrSpecial, zanoSpecial, arbitrumSpecial, zecSpecial, bnbSpecial];

  static CardDesign forCurrencySpecial(CryptoCurrency currency) {
    return specialDesignsForCurrencies[currency] ?? genericDefault;
  }

  static CardDesign forCurrencyIcon(CryptoCurrency currency) {
    return iconDesignsForCurrencies[currency] ?? genericDefault;
  }

  static const Map<CryptoCurrency, CardDesign> iconDesignsForCurrencies = {
    CryptoCurrency.xmr: xmr,
    CryptoCurrency.btc: btc,
    CryptoCurrency.eth: eth,
    CryptoCurrency.ltc: ltc,
    CryptoCurrency.btcln: btcln,
    CryptoCurrency.trx: tron,
    CryptoCurrency.sol: sol,
    CryptoCurrency.maticpoly: pol,
    CryptoCurrency.baseEth: base,
    CryptoCurrency.bch: bch,
    CryptoCurrency.wow: wow,
    CryptoCurrency.doge: doge,
    CryptoCurrency.nano: nano,
    CryptoCurrency.zano: zano,
    CryptoCurrency.arbEth: arbitrum,
    CryptoCurrency.zec: zec,
    CryptoCurrency.dcr: dcr,
    CryptoCurrency.bnb: bnb,

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
    CryptoCurrency.maticpoly: polSpecial,
    CryptoCurrency.dcr: dcrSpecial,
    CryptoCurrency.zano: zanoSpecial,
    CryptoCurrency.baseEth: baseSpecial,
    CryptoCurrency.arbEth: arbitrumSpecial,
    CryptoCurrency.zec: zecSpecial,
    CryptoCurrency.bnb: bnbSpecial,
  };

  static Map<Gradient, CardColorCombination> preferredColorCombinations = {
    CardDesign.gradientOrange: CardColorCombination.dark,
    CardDesign.gradientYellow: CardColorCombination.dark,
    CardDesign.gradientGreen: CardColorCombination.light,
    CardDesign.gradientBlue: CardColorCombination.dark,
    CardDesign.gradientPurple: CardColorCombination.light,
    CardDesign.gradientPink: CardColorCombination.dark,
    CardDesign.gradientRed: CardColorCombination.light,
    CardDesign.gradientSilver: CardColorCombination.dark,
    CardDesign.gradientGold: CardColorCombination.dark,
    CardDesign.gradientBlack: CardColorCombination.black,
  };

  static CardDesign fromStyleSettings(
      BalanceCardStyleSettings? setting, CryptoCurrency walletCurrency) {
    if (setting == null) {
      return CardDesign.forCurrencySpecial(walletCurrency);
    } else if (setting.backgroundImagePath.isNotEmpty) {
      return CardDesign(
        imagePath: setting.backgroundImagePath,
      );
    } else if (setting.useSpecialDesign && setting.gradientIndex != -1) {
      return CardDesign.forCurrencySpecial(walletCurrency)
          .withGradient(CardDesign.allGradients[setting.gradientIndex]);
    } else if (!setting.useSpecialDesign && setting.gradientIndex == -1) {
      final specialColors =
          specialDesignsForCurrencies[walletCurrency] ??
              genericDefault;
      return CardDesign.forCurrencyIcon(walletCurrency)
          .withGradientAndColorCombination(specialColors.gradient, specialColors.colors);
    } else if (setting.useSpecialDesign) {
      return CardDesign.forCurrencySpecial(walletCurrency);
    } else if (setting.gradientIndex != -1) {
      return CardDesign.forCurrencyIcon(walletCurrency)
          .withGradient(CardDesign.allGradients[setting.gradientIndex]);
    } else {
      printV("somehow, the user saved the design settings with literally no customization?");
      return CardDesign.forCurrencySpecial(walletCurrency);
    }
  }
}