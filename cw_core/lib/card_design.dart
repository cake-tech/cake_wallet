import 'package:flutter/material.dart';

enum backgroundTypes { image, svgIcon, svgFull }

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
  final backgroundTypes backgroundType;
  final CardColorCombination colors;

  const CardDesign(
      {this.backgroundType = backgroundTypes.svgIcon,
      required this.gradient,
      this.imagePath = "assets/new-ui/blank.svg",
      this.colors = CardColorCombination.dark});

  static const genericDefault = CardDesign(
      gradient: LinearGradient(
          colors: [Colors.lightBlue, Colors.blue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter));
  static const btc = CardDesign(
      gradient: LinearGradient(
          colors: [Color(0xFFFFD000), Color(0xFFFFAA00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter),
      imagePath: "assets/new-ui/balance_card_icons/bitcoin.svg");
  static const eth = CardDesign(
      gradient: LinearGradient(
          colors: [Color(0xFF9E30FF), Color(0xFF7100BD)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter),
      colors: CardColorCombination.light,
      imagePath: "assets/new-ui/balance_card_icons/ethereum.svg");
  static const btcln = CardDesign(
      gradient: LinearGradient(
          colors: [Color(0xFFE0E8FF), Color(0xFF6D8ADE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter),
      imagePath: "assets/new-ui/balance_card_icons/lightning.svg");
}
