import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/card_design.dart';
import 'package:flutter/material.dart';

class BalanceCardAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? iconSize;

  const BalanceCardAction(
      {required this.label, required this.icon, required this.onTap, this.iconSize = 16});
}

class BalanceCard extends StatelessWidget {
  const BalanceCard(
      {super.key,
      required this.width,
      required this.design,
      this.gradient,
      this.borderRadius = 20,
      this.selected = false,
      this.accountName = "",
      this.accountBalance = "",
      this.balance = "",
      this.fiatBalance = "",
      this.assetName = "",
      this.fiatCurrencyTitle = "",
      this.designSwitchDuration = const Duration(),
      this.actions = const [],
      this.capitalizeAssetName = true,
      this.onCustomizeTapped,
      this.accountIndex,
      this.fiatFirst = false});

  final double width;
  final double borderRadius;
  final Gradient? gradient;
  final String accountBalance;
  final String accountName;
  final String balance;
  final String fiatBalance;
  final String fiatCurrencyTitle;
  final bool fiatFirst;
  final int? accountIndex;
  final bool capitalizeAssetName;
  final String assetName;
  final bool selected;
  final CardDesign design;
  final List<BalanceCardAction> actions;
  final Duration designSwitchDuration;
  final VoidCallback? onCustomizeTapped;

  @override
  Widget build(BuildContext context) {
    final Duration textFadeDuration = Duration(milliseconds: 80);
    final double iconWidth = width * 0.15;

    final name = fiatFirst ? fiatCurrencyTitle : assetName;
    final resolvedAssetName = capitalizeAssetName ? name.toUpperCase() : name.toLowerCase();

    final leadText = fiatFirst ? S.of(context).wallet_balance : accountName;

    final bool showText = accountBalance.isNotEmpty ||
        leadText.isNotEmpty ||
        balance.isNotEmpty ||
        fiatBalance.isNotEmpty ||
        resolvedAssetName.isNotEmpty;

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
                    // Purely decorative card artwork.
                    child: ExcludeSemantics(
                      child: CakeImageWidget(
                        imageUrl: design.imagePath,
                        width: width,
                        height: height,
                        fit: BoxFit.fill,
                      ),
                    ),
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
              mainAxisSize: MainAxisSize.max,
              children: [
                if (showText)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (leadText.isNotEmpty || accountBalance.isNotEmpty)
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
                                          color: design.colors.textColor),
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
                            AnimatedOpacity(
                              opacity: selected ? 0 : 1,
                              duration: textFadeDuration,
                              // Opacity alone keeps the text readable by screen
                              // readers, so drop it while it is invisible.
                              child: ExcludeSemantics(
                                excluding: selected,
                                child: Text(
                                  accountBalance,
                                  style: TextStyle(color: design.colors.textColor, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: textFadeDuration,
                        // Only the selected card's balance is visible, so only it
                        // may be announced.
                        child: ExcludeSemantics(
                          excluding: !selected,
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
                              key: ValueKey("$balance ${resolvedAssetName.toUpperCase()}"),
                              spacing: 8.0,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: designSwitchDuration,
                                  style: DefaultTextStyle.of(context).style.copyWith(
                                      color: design.colors.textColor,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.4),
                                  child: Text(fiatFirst ? fiatBalance : balance),
                                ),
                                AnimatedDefaultTextStyle(
                                  duration: designSwitchDuration,
                                  style: DefaultTextStyle.of(context).style.copyWith(
                                      color: design.colors.textColorSecondary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.4),
                                  child: Text(resolvedAssetName),
                                ),
                              ],
                            ),
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
                          child: Text(
                            key: ValueKey(fiatFirst ? balance : fiatBalance),
                            fiatFirst ? "$assetName $balance" : fiatBalance,
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
                          // Purely decorative card artwork.
                          ? ExcludeSemantics(
                              child: _CornerSvgIcon(design: design, iconWidth: iconWidth),
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
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedOpacity(
              duration: designSwitchDuration,
              opacity: onCustomizeTapped == null ? 0 : 1,
              // Faded out and inert: must not be a focusable phantom control.
              child: ExcludeSemantics(
                excluding: onCustomizeTapped == null,
                child: Semantics(
                  button: true,
                  label: S.of(context).wallet_menu,
                  onTap: onCustomizeTapped,
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    behavior: HitTestBehavior.opaque,
                    onTap: onCustomizeTapped,
                    child: Container(
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
