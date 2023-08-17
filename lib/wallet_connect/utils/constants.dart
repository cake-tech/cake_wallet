import 'package:flutter/material.dart';

class StyleConstants {
  static const Color backgroundColor = Colors.black;
  static const Color primaryColor = Color(0xFF3396FF);

  static const Color darkGray = Color(0xFF141414);
  static const Color lightGray = Color.fromARGB(255, 196, 196, 196);

  static const Color clear = Color.fromARGB(0, 0, 0, 0);
  static const Color layerColor0 = Color(0xFF000000);
  static const Color layerColor1 = Color.fromARGB(255, 18, 18, 19);
  static const Color layerColor1NoAlpha = Color(0xFF141415);
  static const Color layerColor2 = Color.fromARGB(255, 65, 65, 71);
  static const Color layerBubbleColor2 = Color(0xFF798686);
  static const Color layerTextColor2 = Color(0xFF141414);
  static const Color layerColor3 = Color.fromARGB(255, 39, 42, 42);
  static const Color layerTextColor3 = Color(0xFF9EA9A9);
  static const Color layerColor4 = Color(0xFF153B47);
  static const Color layerTextColor4 = Color(0xFF1AC6FF);

  static const Color titleTextColor = Color(0xFFFFFFFF);

  static const Color successColor = Color(0xFF2BEE6C);
  static const Color errorColor = Color(0xFFF25A67);

  // Linear
  static const double linear8 = 8;
  static const double linear16 = 16;
  static const double linear24 = 24;
  static const double linear32 = 32;
  static const double linear48 = 48;
  static const double linear56 = 56;
  static const double linear72 = 72;
  static const double linear80 = 80;

  // Magic Number
  static const double magic10 = 10;
  static const double magic14 = 14;
  static const double magic20 = 20;
  static const double magic40 = 40;
  static const double magic64 = 64;

  // Width
  static const double maxWidth = 400;

  // Text styles
  static const TextStyle titleText = TextStyle(
    color: Colors.white,
    fontSize: magic40,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle subtitleText = TextStyle(
    color: Colors.white,
    fontSize: linear24,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle buttonText = TextStyle(
    color: Colors.white,
    fontSize: linear16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyTextBold = TextStyle(
    color: Colors.white,
    fontSize: magic14,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle bodyText = TextStyle(
    color: Colors.white,
    fontSize: magic14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodyLightGray = TextStyle(
    color: lightGray,
    fontSize: magic14,
  );
  static const TextStyle layerTextStyle2 = TextStyle(
    color: layerTextColor2,
    fontSize: magic14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle layerTextStyle3 = TextStyle(
    color: layerTextColor3,
    fontSize: magic14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle layerTextStyle4 = TextStyle(
    color: layerTextColor4,
    fontSize: magic14,
    fontWeight: FontWeight.w600,
  );

  // Bubbles
  static const EdgeInsets bubblePadding = EdgeInsets.symmetric(
    vertical: linear8,
    horizontal: linear8,
  );
}
