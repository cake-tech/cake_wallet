import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard(
      {super.key,
      required this.width,
      required this.selected,
      required this.accountName,
      required this.accountBalance,
      required this.balance,
      required this.fiatBalance,
      required this.assetName,
      required this.design});

  final double width;
  final String accountBalance;
  final String accountName;
  final String balance;
  final String fiatBalance;
  final String assetName;
  final bool selected;
  final CardDesign design;

  @override
  Widget build(BuildContext context) {
    final Duration textFadeDuration = Duration(milliseconds: 80);

    return Container(
      width: width,
      height: width * 2.0 / 3,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0x77FFFFFF), width: 1),
        gradient: design.gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                        style: TextStyle(color: design.colors.textColorSecondary, fontSize: 28),
                      ),
                    ],
                  ),
                ),
                Text(
                  fiatBalance,
                  style: TextStyle(color: design.colors.textColorSecondary, fontSize: 20),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                ),
                SvgPicture.asset(
                  design.imagePath,
                  height: 50,
                  width: 50,
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
    );
  }
}
