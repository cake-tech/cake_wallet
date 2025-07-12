import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class CakePayTransactionSentBottomSheet extends StatelessWidget {
  const CakePayTransactionSentBottomSheet({
    super.key,
    required this.titleText,
    required this.currency,
    required this.amount,
    required this.amountValue,
    required this.fiatAmountValue,
    required this.output,
    required this.fee,
    required this.feeValue,
    required this.feeFiatAmount,
    this.titleIconWidget,
    required this.quantity,
    required this.onClose,
    required this.paymentId,
    required this.paymentIdValue,
  });

  final String titleText;
  final Widget? titleIconWidget;
  final CryptoCurrency currency;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final Output output;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final String quantity;
  final VoidCallback onClose;
  final String paymentId;
  final String paymentIdValue;

  TextStyle _titleStyle(BuildContext ctx) => Theme.of(ctx).textTheme.bodyLarge!;

  TextStyle _valueStyle(BuildContext ctx) => Theme.of(ctx).textTheme.titleMedium!.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  TextStyle _subStyle(BuildContext ctx) => Theme.of(ctx).textTheme.labelSmall!.copyWith(
        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
      );

  Widget _buildHeader(BuildContext ctx) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (titleIconWidget != null) titleIconWidget!,
              const SizedBox(width: 6),
              Text(
                titleText,
                style: Theme.of(ctx).textTheme.titleLarge!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );

  Widget _buildBody(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            _StandardTile(
              itemTitle: amount,
              titleStyle: _titleStyle(context),
              itemValue: '$amountValue ${currency.title}',
              itemValueStyle: _valueStyle(context),
              itemSubTitle: fiatAmountValue,
              itemSubTitleStyle: _subStyle(context),
            ),
            const SizedBox(height: 8),
            _StandardTile(
              itemTitle: fee,
              titleStyle: _titleStyle(context),
              itemValue: feeValue,
              itemValueStyle: _valueStyle(context),
              itemSubTitle: feeFiatAmount,
              itemSubTitleStyle: _subStyle(context),
            ),
            const SizedBox(height: 8),
            _StandardTile(
              itemTitle: output.parsedAddress.profileName,
              titleStyle: _titleStyle(context),
              itemValue: output.fiatAmount,
              itemValueStyle: _valueStyle(context),
              itemSubTitle: quantity,
              itemSubTitleStyle: _subStyle(context),
              imagePath: output.parsedAddress.profileImageUrl,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(paymentId + ': ' + paymentIdValue,
                      style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  Image.asset('assets/images/envelope.png'),
                  const SizedBox(height: 18),
                  Text(
                    S.of(context).cake_pay_card_email_delivered_message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: S.of(context).close,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                _buildBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StandardTile extends StatelessWidget {
  const _StandardTile({
    required this.itemTitle,
    required this.titleStyle,
    required this.itemValue,
    required this.itemValueStyle,
    this.itemSubTitle,
    this.itemSubTitleStyle,
    this.imagePath,
  });

  final String itemTitle;
  final TextStyle titleStyle;
  final String itemValue;
  final TextStyle itemValueStyle;
  final String? itemSubTitle;
  final TextStyle? itemSubTitleStyle;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: itemTitle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).colorScheme.surfaceContainerLowest.withAlpha(80)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ImageUtil.getImageFromPath(
                            imagePath: imagePath!, height: 40, width: 40),
                      ),
                    ),
                  Flexible(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          itemTitle,
                          style: titleStyle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        )),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(itemValue, style: itemValueStyle.copyWith(height: 1.0)),
                if (itemSubTitle != null) Text(itemSubTitle!, style: itemSubTitleStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
