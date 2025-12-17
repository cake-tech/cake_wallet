import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BalanceCardAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const BalanceCardAction({required this.label, required this.icon, required this.onTap});
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.width,
    required this.design,
    this.borderRadius = 20,
    this.selected = false,
    this.accountName = "",
    this.accountBalance = "",
    this.balance = "",
    this.fiatBalance = "",
    this.assetName = "",
    this.designSwitchDuration = const Duration(),
    this.actions = const [],
  });

  final double width;
  final double borderRadius;
  final String accountBalance;
  final String accountName;
  final String balance;
  final String fiatBalance;
  final String assetName;
  final bool selected;
  final CardDesign design;
  final List<BalanceCardAction> actions;
  final Duration designSwitchDuration;

  @override
  Widget build(BuildContext context) {
    final Duration textFadeDuration = Duration(milliseconds: 80);
    final double iconWidth = width * 0.15;

    final bool showText = accountBalance.isNotEmpty ||
        accountName.isNotEmpty ||
        balance.isNotEmpty ||
        fiatBalance.isNotEmpty ||
        assetName.isNotEmpty;

    final height = width * 0.62;

    return AnimatedContainer(
      duration: designSwitchDuration,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        gradient: design.gradient,
        shape: RoundedSuperellipseBorder(
          side: const BorderSide(color: Color(0x77FFFFFF), width: 1),
          borderRadius: BorderRadiusGeometry.circular(borderRadius),
        ),
      ),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: designSwitchDuration,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: design.backgroundType == CardDesignBackgroundTypes.svgFull
                ? SvgPicture.asset(
                    design.imagePath,
                    key: const ValueKey('svgFull'),
                    width: width,
                    height: height,
                  )
                : const SizedBox.shrink(
                    key: ValueKey('svgFullOff'),
                  ),
          ),
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
                          AnimatedDefaultTextStyle(
                            duration: designSwitchDuration,
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w500,
                                color: design.colors.textColor),
                            child: Text(accountName),
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
                            AnimatedDefaultTextStyle(
                              duration: designSwitchDuration,
                              style: DefaultTextStyle.of(context)
                                  .style
                                  .copyWith(color: design.colors.textColor, fontSize: 28, fontWeight: FontWeight.w500),
                              child: Text(
                                balance,
                              ),
                            ),
                            AnimatedDefaultTextStyle(
                              duration: designSwitchDuration,
                              style: DefaultTextStyle.of(context)
                                  .style
                                  .copyWith(color: design.colors.textColorSecondary, fontSize: 28, fontWeight: FontWeight.w400),
                              child: Text(
                                assetName.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fiatBalance,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: design.colors.textColorSecondary),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: actions.map(getBalanceCardActionButton).toList(),
                    ),
                    AnimatedSwitcher(
                      duration: designSwitchDuration,
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: design.backgroundType == CardDesignBackgroundTypes.svgIcon
                          ? SvgPicture.asset(
                              design.imagePath,
                              key: const ValueKey('svgIcon'),
                              height: iconWidth,
                              width: iconWidth,
                              colorFilter: ColorFilter.mode(
                                design.colors.backgroundImageColor.withAlpha(215),
                                BlendMode.srcIn,
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('svgIconOff'),
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

  Widget getBalanceCardActionButton(BalanceCardAction action) => GestureDetector(
        onTap: action.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: design.colors.backgroundImageColor.withAlpha(75),
            borderRadius: BorderRadius.circular(10000000),
          ),
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.only(left: 10, right: 5, top: 5, bottom: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  action.label,
                  style: TextStyle(color: design.colors.textColor, fontSize: 16),
                ),
              ),
              Icon(action.icon, color: design.colors.textColorSecondary),
            ],
          ),
        ),
      );
}
