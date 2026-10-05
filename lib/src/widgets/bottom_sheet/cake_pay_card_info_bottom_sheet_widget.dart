import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/cake_pay/src/widgets/flip_card_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/link_extractor.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'base_bottom_sheet_widget.dart';

class CakePayCardInfoBottomSheet extends BaseBottomSheet {
  CakePayCardInfoBottomSheet({
    required String titleText,
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
    required this.balance,
    this.cardNumber,
    required this.cardNumberLabel,
    this.pin,
    this.contentImage,
    this.howToUse,
    this.applyBoxShadow = false,
    Key? key,
  }) : super(
            titleText: titleText,
            maxHeight: 900,
            titleIconPath: titleIconPath,
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

  final String? contentImage;
  final String? howToUse;
  final String balance;
  final String? cardNumber;
  final String cardNumberLabel;
  final String? pin;
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
                      back: _buildBarcodeSide(
                        context,
                        cardNumber: cardNumber,
                        cardNumberLabel: cardNumberLabel,
                        pin: pin,
                      ),
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
              Text(S.of(context).how_to_use_card, style: Theme.of(context).textTheme.bodyLarge),
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
    required this.itemValue,
    required this.itemTitleTextStyle,
    this.itemSubTitle,
    required this.itemSubTitleTextStyle,
    required this.tileBackgroundColor,
  });

  final String itemValue;
  final TextStyle itemTitleTextStyle;
  final String? itemSubTitle;
  final TextStyle itemSubTitleTextStyle;
  final Color tileBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: S.of(context).total_value,
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
                Text(S.of(context).total_value, style: itemTitleTextStyle),
                Text(itemValue,
                    style: itemTitleTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
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
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 5)],
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

Widget _buildBarcodeSide(
  BuildContext context, {
  String? cardNumber,
  required String cardNumberLabel,
  String? pin,
}) =>
    SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 34),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(200),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(150), blurRadius: 5)],
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
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (cardNumber != null)
                  Flexible(
                    child: _CopyableField(
                      key: const ValueKey('cake_pay_card_info_number_field_key'),
                      label: cardNumberLabel,
                      value: cardNumber,
                    ),
                  ),
                if (pin != null) ...[
                  const SizedBox(width: 12),
                  _CopyableField(
                    key: const ValueKey('cake_pay_card_info_pin_field_key'),
                    label: S.of(context).pin_number,
                    value: pin,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

class _CopyableField extends StatelessWidget {
  const _CopyableField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color.fromRGBO(207, 207, 207, 1),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color.fromRGBO(146, 146, 146, 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: '${S.of(context).copy} $label',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: value));

                if (context.mounted) {
                  await showBar<void>(context, S.of(context).copied_to_clipboard);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: Color.fromRGBO(146, 146, 146, 1),
                ),
              ),
            ),
          ),
        ],
      );
}
