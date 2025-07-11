import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/cake_pay/src/widgets/flip_card_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/link_extractor.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

import 'base_bottom_sheet_widget.dart';

class CakePayCardInfoBottomSheet extends BaseBottomSheet {
  CakePayCardInfoBottomSheet({
    required String titleText,
    required MaterialThemeBase currentTheme,
    required FooterType footerType,
    String? titleIconPath,
    String? singleActionButtonText,
    VoidCallback? onSingleActionButtonPressed,
    Key? singleActionButtonKey,
    String? doubleActionLeftButtonText,
    String? doubleActionRightButtonText,
    VoidCallback? onLeftActionButtonPressed,
    VoidCallback? onRightActionButtonPressed,
    Key? rightActionButtonKey,
    Key? leftActionButtonKey,
    required this.onUpdateBalancePressed,
    required this.isReloadable,
    required this.balance,
    this.contentImage,
    this.howToUse,
    this.applyBoxShadow = false,
    Key? key,
  })  : _currentTheme = currentTheme,
        super(
            titleText: titleText,
            maxHeight: 900,
            titleIconPath: titleIconPath,
            currentTheme: currentTheme,
            footerType: footerType,
            singleActionButtonText: singleActionButtonText,
            onSingleActionButtonPressed: onSingleActionButtonPressed,
            singleActionButtonKey: singleActionButtonKey,
            doubleActionLeftButtonText: doubleActionLeftButtonText,
            doubleActionRightButtonText: doubleActionRightButtonText,
            onLeftActionButtonPressed: onLeftActionButtonPressed,
            onRightActionButtonPressed: onRightActionButtonPressed,
            leftActionButtonKey: leftActionButtonKey,
            rightActionButtonKey: rightActionButtonKey,
            key: key);

  final VoidCallback onUpdateBalancePressed;
  final MaterialThemeBase _currentTheme;
  final String? contentImage;
  final String? howToUse;
  final bool isReloadable;
  final String balance;
  final bool applyBoxShadow;

  final _cardKey = GlobalKey<FlipCardState>();

  @override
  Widget contentWidget(BuildContext context) {
    final itemTitleTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    );
    final itemSubTitleTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      decoration: TextDecoration.none,
    );

    final tileBackgroundColor = Theme.of(context).colorScheme.surfaceContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (contentImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 16),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: FlipCard(
                      key: _cardKey,
                      flipOnTouch: true,
                      front: _buildCardImage(context, contentImage!, applyBoxShadow),
                      back: _buildBarcodeSide(context,
                          cardNumber: '6006491979836784204', pin: '4782'),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _cardKey.currentState?.toggleCard(),
                    child: Container(
                        height: 43,
                        width: 43,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          color: Colors.white.withAlpha(75),
                          shape: BoxShape.circle,
                        ),
                        child: Transform.scale(
                          scale: .8,
                          child: const ImageIcon(
                            AssetImage('assets/images/transfer.png'),
                            color: Colors.white,
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ),
        Container(),
        Text(
          'Tap card to show details',
          style: itemTitleTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              const SizedBox(height: 34),
              CakePayInfoTile(
                  isReloadable: isReloadable,
                  itemValue: balance,
                  itemTitleTextStyle: itemTitleTextStyle,
                  itemSubTitleTextStyle: itemSubTitleTextStyle,
                  tileBackgroundColor: tileBackgroundColor),
              const SizedBox(height: 8),
              _HowToUseTile(howToUse: howToUse ?? '', tileBackgroundColor: tileBackgroundColor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowToUseTile extends StatelessWidget {
  const _HowToUseTile({required this.howToUse, required this.tileBackgroundColor});

  final String howToUse;
  final Color tileBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showHowToUseCard(context: context, howToUse: howToUse),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(10), color: tileBackgroundColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).how_to_use_card,
                style: Theme.of(context).textTheme.bodyLarge),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).textTheme.titleLarge!.color!,
              ),
            ],
          )),
    );
  }
}

class CakePayInfoTile extends StatelessWidget {
  const CakePayInfoTile({
    super.key,
    required this.isReloadable,
    required this.itemValue,
    required this.itemTitleTextStyle,
    this.itemSubTitle,
    required this.itemSubTitleTextStyle,
    required this.tileBackgroundColor,
  });

  final bool isReloadable;
  final String itemValue;
  final TextStyle itemTitleTextStyle;
  final String? itemSubTitle;
  final TextStyle itemSubTitleTextStyle;
  final Color tileBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: isReloadable ? 'Balance' : 'Total Value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(10), color: tileBackgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isReloadable ? 'Balance' : 'Total Value', style: itemTitleTextStyle),
                Text(itemValue,
                    style: itemTitleTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(isReloadable ? 'Top Up Balance' : 'Manually update Balance',
                    style: itemTitleTextStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).dialogBackgroundColor)),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

void _showHowToUseCard({required BuildContext context, String? howToUse}) {
  showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return CakePayAlertModal(
          title: S.of(context).how_to_use_card,
          content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClickableLinksText(
              text: howToUse ?? '',
              textStyle: Theme.of(context).textTheme.bodyMedium!,
              linkStyle: TextStyle(
                color: Theme.of(context).textTheme.titleLarge!.color!,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
              ),
            ),
          ]),
          actionTitle: S.current.got_it,
        );
      });
}

Widget _buildCardImage(BuildContext ctx, String path, bool addShadow) {
  final border = BorderRadius.circular(10);

  return Container(
    decoration: addShadow
        ? BoxDecoration(
      borderRadius: border,
      boxShadow: [
        BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 5)
      ],
    )
        : null,
    child: ClipRRect(
      borderRadius: border,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Theme.of(ctx).cardColor.withAlpha(200)),
          ImageUtil.getImageFromPath(
            imagePath: path,
            fit: BoxFit.cover,
          ),
        ],
      ),
    ),
  );
}

Widget _buildBarcodeSide(BuildContext context, {required String cardNumber, required String pin}) =>
    SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 34),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(200),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).textTheme.titleLarge!.color!.withOpacity(.1),
              
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gift Card Number',
                        style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(207, 207, 207, 1))),
                    const SizedBox(height: 4),
                    Text(cardNumber,
                        style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color.fromRGBO(146, 146, 146, 1))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIN Number',
                        style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(207, 207, 207, 1))),
                    const SizedBox(height: 4),
                    Text(pin,
                        style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color.fromRGBO(146, 146, 146, 1))),
                  ],
                ),
              ],
            ),

          ],
        ),
      ),
    );
