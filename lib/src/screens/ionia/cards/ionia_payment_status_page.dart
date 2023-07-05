import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/view_model/ionia/ionia_payment_status_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class IoniaPaymentStatusPage extends BasePage {
  IoniaPaymentStatusPage(this.viewModel);

  final IoniaPaymentStatusViewModel viewModel;

  @override
    Widget middle(BuildContext context) {
      return Text(
        S.of(context).generating_gift_card,
        textAlign: TextAlign.center,
        style: textMediumSemiBold(
            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor));
  }

  @override
  Widget body(BuildContext context) {
    return _IoniaPaymentStatusPageBody(viewModel);
  }
}

class _IoniaPaymentStatusPageBody extends StatefulWidget {
  _IoniaPaymentStatusPageBody(this.viewModel);

  final IoniaPaymentStatusViewModel viewModel;

  @override
  _IoniaPaymentStatusPageBodyBodyState createState() => _IoniaPaymentStatusPageBodyBodyState();
}

class _IoniaPaymentStatusPageBodyBodyState extends State<_IoniaPaymentStatusPageBody> {
  ReactionDisposer? _onGiftCardReaction;

  @override
  void initState() {
    if (widget.viewModel.giftCard != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
          .pushReplacementNamed(Routes.ioniaGiftCardDetailPage, arguments: [widget.viewModel.giftCard]);
      });
    }

    _onGiftCardReaction = reaction((_) => widget.viewModel.giftCard, (IoniaGiftCard? giftCard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
          .pushReplacementNamed(Routes.ioniaGiftCardDetailPage, arguments: [giftCard]);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _onGiftCardReaction?.reaction.dispose();
    widget.viewModel.timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(children: [
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green),
                height: 10,
                width: 10)),
            Text(
              S.of(context).awaiting_payment_confirmation,
              style: textLargeSemiBold(
                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor))
            ]),
          SizedBox(height: 40),
          Row(children: [
            SizedBox(width: 20),
            Expanded(child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ...widget.viewModel
                    .committedInfo
                    .transactions
                    .map((transaction) => buildDescriptionTileWithCopy(context, S.of(context).transaction_details_transaction_id, transaction.id)),
                  if (widget.viewModel.paymentInfo.ioniaOrder.id != null)
                    ...[Divider(height: 30),
                    buildDescriptionTileWithCopy(context, S.of(context).order_id, widget.viewModel.paymentInfo.ioniaOrder.id)],
                  if (widget.viewModel.paymentInfo.ioniaOrder.paymentId != null)
                    ...[Divider(height: 30),
                    buildDescriptionTileWithCopy(context, S.of(context).payment_id, widget.viewModel.paymentInfo.ioniaOrder.paymentId)],
                  ]))
                ]),
          SizedBox(height: 40),
          Observer(builder: (_) {
            if (widget.viewModel.giftCard != null) {
              return Container(
                padding: EdgeInsets.only(top: 40),
                child: Row(children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10,),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.green),
                      height: 10,
                      width: 10)),
                  Text(
                    S.of(context).gift_card_is_generated,
                    style: textLargeSemiBold(
                      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor))
                  ]));
            }

            return Row(children: [
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Observer(builder: (_) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: widget.viewModel.giftCard == null ? Colors.grey : Colors.green),
                    height: 10,
                    width: 10);
                  })),
              Text(
                S.of(context).generating_gift_card,
                style: textLargeSemiBold(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor))]);
          }),
        ],
      ),
      bottomSection: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Column(children: [
            Container(
              padding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
              child: Text(
                widget.viewModel.payingByBitcoin ? S.of(context).bitcoin_payments_require_1_confirmation
                    : S.of(context).proceed_after_one_minute,
                style: textMedium(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                ).copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              )),
              Observer(builder: (_) {
                if (widget.viewModel.giftCard != null) {
                  return PrimaryButton(
                    onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(
                        Routes.ioniaGiftCardDetailPage,
                        arguments: [widget.viewModel.giftCard]),
                    text: S.of(context).open_gift_card,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white);
                }

                return PrimaryButton(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.support),
                  text: S.of(context).contact_support,
                  color: Theme.of(context).cardColor,
                  textColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor);
                })
            ])
      ),
    );
  }

  Widget buildDescriptionTile(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textXSmall(
              color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: textMedium(
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
            ),
          ),
        ],
      ));
  }

  Widget buildDescriptionTileWithCopy(BuildContext context, String title, String subtitle) {
    return buildDescriptionTile(context, title, subtitle, () {
      Clipboard.setData(ClipboardData(text: subtitle));
        showBar<void>(context,
            S.of(context).transaction_details_copied(title));
      });
  }
}