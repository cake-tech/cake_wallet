import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';

class RoundedOverlayCards extends StatelessWidget {
  const RoundedOverlayCards({
    this.topCardChild = const SizedBox(),
    this.bottomCardChild = const SizedBox(),
  });

  final Widget topCardChild;
  final Widget bottomCardChild;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return ClipRRect(
      borderRadius:
      BorderRadius.only(bottomLeft: Radius.circular(25.0), bottomRight: Radius.circular(25.0)),
      child: Container(
        height: screenHeight * 0.53,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor,
              Theme.of(context).extension<ExchangePageTheme>()!.secondGradientBottomPanelColor,
            ],
            stops: [0.35, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25.0), bottomRight: Radius.circular(25.0)),
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).extension<ExchangePageTheme>()!.firstGradientTopPanelColor,
                          Theme.of(context).extension<ExchangePageTheme>()!.secondGradientTopPanelColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    height: screenHeight * 0.35,
                    width: double.infinity,
                    child: topCardChild)),
            bottomCardChild,
          ],
        ),
      ),
    );
  }
}