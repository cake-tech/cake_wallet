import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.width,
    required this.balanceRecord,
    required this.selected,
    required this.accountName,
    required this.accountBalance,
    required this.gradient,
    required this.svgPath,
    required this.lightningMode,
  });

  final double width;
  final String accountBalance;
  final String accountName;
  final Gradient gradient;
  final String svgPath;
  final BalanceRecord balanceRecord;
  final bool selected;
  final bool lightningMode;

  @override
  Widget build(BuildContext context) {
    final Duration textFadeDuration = Duration(milliseconds: 80);

    return Container(
      width: width,
      height: width * 2.0 / 3,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0x77FFFFFF), width: 1),
        gradient: gradient,
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
                      style: TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    AnimatedOpacity(
                      opacity: selected ? 0 : 1,
                      duration: textFadeDuration,
                      child: Text(
                        accountBalance,
                        style: TextStyle(color: Colors.black, fontSize: 14),
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
                        lightningMode
                            ? balanceRecord.secondAvailableBalance
                            : balanceRecord.availableBalance,
                        style: TextStyle(color: Colors.black, fontSize: 28),
                      ),
                      Text(
                        balanceRecord.asset.name.toUpperCase(),
                        style: TextStyle(color: Colors.black45, fontSize: 28),
                      ),
                    ],
                  ),
                ),
                Text(
                  lightningMode
                      ? balanceRecord.fiatSecondAdditionalBalance
                      : balanceRecord.fiatAvailableBalance,
                  style: TextStyle(color: Colors.black45, fontSize: 20),
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
                    color: Color(0x44FFFFFF),
                    borderRadius: BorderRadius.circular(10000000),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          "Buy",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.black45),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  svgPath,
                  height: 50,
                  width: 50,
                  colorFilter: const ColorFilter.mode(
                    Color(0xBBFFFFFF),
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
