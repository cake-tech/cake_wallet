import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/themes/theme_base.dart';

class TradeDetailsStandardListCard extends StatelessWidget {
  TradeDetailsStandardListCard(
      {required this.id,
      required this.create,
      required this.pair,
      required this.onTap,
      required this.currentTheme});

  final String id;
  final String create;
  final String pair;
  final ThemeType currentTheme;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    final darkTheme = currentTheme == ThemeType.dark;

    final baseGradient = LinearGradient(colors: [
      Theme.of(context).extension<ExchangePageTheme>()!.firstGradientTopPanelColor,
      Theme.of(context).extension<ExchangePageTheme>()!.secondGradientTopPanelColor,
    ], begin: Alignment.centerLeft, end: Alignment.centerRight);

    final gradient = LinearGradient(colors: [
      PaletteDark.wildNightBlue,
      PaletteDark.oceanBlue,
    ], begin: Alignment.bottomCenter, end: Alignment.topCenter);

    final textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: GestureDetector(
        onTap: () => onTap(context),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              gradient: darkTheme ? gradient : baseGradient),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id,
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          color: textColor)),
                  SizedBox(
                    height: 8,
                  ),
                  Text(create,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          color: textColor)),
                  SizedBox(
                    height: 35,
                  ),
                  Text(pair,
                      style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ]),
          ),
        ),
      ),
    );
  }
}
