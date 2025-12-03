import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard(
      {super.key,
      required this.width,
        this.borderRadius = 20,
      this.selected = false,
      this.accountName = "",
      this.accountBalance = "",
      this.balance = "",
      this.fiatBalance = "",
      this.assetName = "",
      required this.design,
      this.showBuyActions = true});

  final double width;
  final double borderRadius;
  final String accountBalance;
  final String accountName;
  final String balance;
  final String fiatBalance;
  final String assetName;
  final bool selected;
  final bool showBuyActions;
  final CardDesign design;

  @override
  Widget build(BuildContext context) {
    final Duration textFadeDuration = Duration(milliseconds: 80);
    final double iconWidth = width * 0.15;

    final bool showText = accountBalance.isNotEmpty ||
        accountName.isNotEmpty ||
        balance.isNotEmpty ||
        fiatBalance.isNotEmpty ||
        assetName.isNotEmpty;

    final height = width * 0.64;

    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
          gradient: design.gradient,
          shape: RoundedSuperellipseBorder(side: BorderSide(color: Color(0x77FFFFFF), width: 1), borderRadius: BorderRadiusGeometry.circular(borderRadius))
      ),
      child: Stack(
        children: [
          if (design.backgroundType == CardDesignBackgroundTypes.svgFull)
            SvgPicture.asset(design.imagePath, width: width, height: height),
          Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showText)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            accountName,
                            style: TextStyle(color: design.colors.textColor, fontSize: 20),
                          ),
                          AnimatedOpacity(
                            opacity: selected ? 0 : 1,
                            duration: textFadeDuration,
                            child: Text(
                              accountBalance,
                              style: TextStyle(color: design.colors.textColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: textFadeDuration,
                        child: Row(
                          spacing: 8.0,
                          children: [
                            Text(
                              balance,
                              style: TextStyle(color: design.colors.textColor, fontSize: 28),
                            ),
                            Text(
                              assetName.toUpperCase(),
                              style:
                                  TextStyle(color: design.colors.textColorSecondary, fontSize: 28),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fiatBalance,
                        style: TextStyle(color: design.colors.textColorSecondary, fontSize: 20),
                      ),
                    ],
                  )
                else
                  Container(),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showBuyActions)
                      Container(
                        decoration: BoxDecoration(
                          color: design.colors.backgroundImageColor,
                          borderRadius: BorderRadius.circular(10000000),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(
                                "Buy",
                                style: TextStyle(color: design.colors.textColor, fontSize: 16),
                              ),
                            ),
                            Icon(Icons.arrow_forward, color: design.colors.textColorSecondary),
                          ],
                        ),
                      )
                    else
                      Container(),
                    if (design.backgroundType == CardDesignBackgroundTypes.svgIcon)
                      SvgPicture.asset(
                        design.imagePath,
                        height: iconWidth,
                        width: iconWidth,
                        colorFilter: ColorFilter.mode(
                          design.colors.backgroundImageColor,
                          BlendMode.srcIn,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
