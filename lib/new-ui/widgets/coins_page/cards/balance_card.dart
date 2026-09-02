import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/money/currency_symbol_text.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency/fiat_currency.dart";
import "package:flutter/material.dart";

class BalanceCardAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? iconSize;

  const BalanceCardAction(
      {required this.label, required this.icon, required this.onTap, this.iconSize = 16});
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.width,
    required this.design,
    required this.asset,
    super.key,
    this.gradient,
    this.borderRadius = 20,
    this.selected = false,
    this.accountName = "",
    this.accountBalance,
    this.balance,
    this.fiatBalance,
    this.fiatCurrency,
    this.designSwitchDuration = Duration.zero,
    this.actions = const [],
    this.onCustomizeTapped,
    this.accountIndex,
    this.fiatFirst = false,
  });

  final double width;
  final double borderRadius;
  final Gradient? gradient;
  final Money? balance;
  final Money? fiatBalance;
  final String accountName;
  final Money? accountBalance;
  final bool fiatFirst;
  final int? accountIndex;
  final CryptoCurrency asset;
  final FiatCurrency? fiatCurrency;
  final bool selected;
  final CardDesign design;
  final List<BalanceCardAction> actions;
  final Duration designSwitchDuration;
  final VoidCallback? onCustomizeTapped;

  @override
  Widget build(BuildContext context) {
    const textFadeDuration = Duration(milliseconds: 80);
    final iconWidth = width * 0.15;

    final resolvedCurrency = fiatFirst && fiatCurrency != null ? fiatCurrency! : asset;

    final leadText = fiatFirst ? S.of(context).wallet_balance : accountName;

    final bool showText = accountBalance != null ||
        leadText.isNotEmpty ||
        balance != null ||
        fiatBalance != null;

    final height = width * 0.62;

    return AnimatedContainer(
      duration: designSwitchDuration,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        gradient: gradient ?? design.gradient,
        shape: RoundedSuperellipseBorder(
          side: const BorderSide(color: Color(0x44FFFFFF), width: 1),
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
                ? ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(borderRadius),
                    key: ValueKey(design.imagePath),
                    child: ExcludeSemantics(
                      child: CakeImageWidget(
                        imageUrl: design.imagePath,
                        width: width,
                        height: height,
                        fit: BoxFit.fill,
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey("svgFullOff")),
          ),
          Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (showText)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (leadText.isNotEmpty || accountBalance != null)
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              spacing: 4,
                              children: [
                                if (accountIndex != null)
                                  Opacity(
                                    opacity: 0.5,
                                    child: AnimatedDefaultTextStyle(
                                      duration: designSwitchDuration,
                                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: design.colors.textColor,
                                          ),
                                      child: Text("$accountIndex."),
                                    ),
                                  ),
                                AnimatedDefaultTextStyle(
                                  duration: designSwitchDuration,
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: design.colors.textColor
                                          .withAlpha(leadText == accountName ? 255 : 128)),
                                  child: Text(leadText),
                                ),
                              ],
                            ),
                            if (accountBalance != null)
                              AnimatedOpacity(
                                opacity: selected ? 0 : 1,
                                duration: textFadeDuration,
                                child: MoneyText(
                                  accountBalance!,
                                  fractionalDigits: 2,
                                  trimZeros: false,
                                  showSymbol: false,
                                  style: TextStyle(color: design.colors.textColor, fontSize: 14),
                                ),
                              ),
                          ],
                        ),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: textFadeDuration,
                        child: AnimatedSwitcher(
                          duration: designSwitchDuration,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          child: Row(
                            key: ValueKey("$balance ${resolvedCurrency.symbol.toUpperCase()}"),
                            spacing: 8,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: designSwitchDuration,
                                style: DefaultTextStyle.of(context).style.copyWith(
                                    color: design.colors.textColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.4,
                                ),
                                child: MoneyText.optional(
                                  fiatFirst ? fiatBalance : balance,
                                  trimZeros: !fiatFirst,
                                  showSymbol: false,
                                ),
                              ),
                              AnimatedDefaultTextStyle(
                                duration: designSwitchDuration,
                                style: DefaultTextStyle.of(context).style.copyWith(
                                    color: design.colors.textColorSecondary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.4),
                                child: CurrencySymbolText(resolvedCurrency),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: designSwitchDuration,
                        style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: design.colors.textColorSecondary),
                        child: AnimatedSwitcher(
                          duration: designSwitchDuration,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          child: MoneyText.optional(
                            fiatFirst ? balance : fiatBalance,
                            withSymbolPrefix: true,
                            trimZeros: fiatFirst,
                            key: const ValueKey("balance_card_sub_balance"),
                          ),
                        ),
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
                    AnimatedSwitcher(
                      duration: designSwitchDuration,
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: Row(
                        key: ValueKey(actions.toString()),
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: actions.map(getBalanceCardActionButton).toList(),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: designSwitchDuration,
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: design.backgroundType == CardDesignBackgroundTypes.svgIcon
                          ? _CornerSvgIcon(design: design, iconWidth: iconWidth)
                          : const SizedBox.shrink(
                              key: ValueKey("svgIconOff"),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedOpacity(
              duration: designSwitchDuration,
              opacity: onCustomizeTapped == null ? 0 : 1,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCustomizeTapped,
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(
                    child: CakeImageWidget(
                      imageUrl: "assets/new-ui/3dots_vertical.svg",
                      alignment: Alignment.topRight,
                      colorFilter:
                          ColorFilter.mode(design.colors.textColorSecondary, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget getBalanceCardActionButton(BalanceCardAction action) => Semantics(
        button: true,
        label: action.label,
        onTap: action.onTap,
        child: ExcludeSemantics(
          child: GestureDetector(
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
                  Icon(action.icon, color: design.colors.textColorSecondary, size: action.iconSize),
                ],
              ),
            ),
          ),
        ),
      );
}

class _CornerSvgIcon extends StatelessWidget {
  const _CornerSvgIcon({required this.design, required this.iconWidth});

  final CardDesign design;
  final double iconWidth;

  @override
  Widget build(BuildContext context) {
    return CakeImageWidget(
      imageUrl: design.imagePath,
      key: ValueKey(design.imagePath),
      height: iconWidth,
      width: iconWidth,
      colorFilter: design.preColoredIcon
          ? null
          : ColorFilter.mode(
              design.colors.backgroundImageColor.withValues(alpha: 0.33),
              BlendMode.dstIn,
            ),
    );
  }
}
