import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_alert_model.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/cake_pay_purchase_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class CakePayBuyCardDetailPage extends BasePage {
  CakePayBuyCardDetailPage(this.cakePayPurchaseViewModel);

  final CakePayPurchaseViewModel cakePayPurchaseViewModel;

  @override
  Widget middle(BuildContext context) {
    return Text(
      cakePayPurchaseViewModel.card.name,
      style: textMediumSemiBold(color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
    );
  }

  @override
  Widget? trailing(BuildContext context) => null;

  @override
  Widget body(BuildContext context) {
    final card = cakePayPurchaseViewModel.card;

    reaction((_) => cakePayPurchaseViewModel.orderCreationState, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _showConfirmSendingAlert(context);
        });
      }
    });

    reaction((_) => cakePayPurchaseViewModel.invoiceCommittingState, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(Routes.ioniaPaymentStatusPage,
              arguments: [cakePayPurchaseViewModel.order, cakePayPurchaseViewModel.committedInfo]);
        });
      }
    });

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.zero,
      content: Observer(builder: (_) {
        final tipAmount = cakePayPurchaseViewModel.tipAmount;
        return Column(
          children: [
            SizedBox(height: 36),
            ClipRRect(
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                          child: ClipRRect(
                        borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(20), right: Radius.circular(20)),
                        child: Image.network(
                          card.cardImageUrl ?? '',
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _PlaceholderContainer(text: 'Logo not found!'),
                        ),
                      )),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        child: Column(children: [
                          Text(
                            S.of(context).gift_card_amount,
                            style: textSmall(),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$${cakePayPurchaseViewModel.giftCardAmount.toStringAsFixed(2)}',
                            style: textXLargeSemiBold(),
                          ),
                        ]),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextIconButton(
                label: S.of(context).how_to_use_card,
                onTap: () => _showHowToUseCard(context, card),
              ),
            ),
          ],
        );
      }),
      bottomSection: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Observer(builder: (_) {
              return LoadingPrimaryButton(
                isLoading: cakePayPurchaseViewModel.orderCreationState is IsExecutingState ||
                    cakePayPurchaseViewModel.invoiceCommittingState is IsExecutingState,
                onPressed: () => purchaseCard(context),
                text: S.of(context).purchase_gift_card,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
              );
            }),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () => _showTermsAndCondition(context),
            child: Text(S.of(context).settings_terms_and_conditions,
                style: textMediumSemiBold(
                  color: Theme.of(context)
                      .extension<ExchangePageTheme>()!
                      .firstGradientBottomPanelColor,
                ).copyWith(fontSize: 12)),
          ),
          SizedBox(height: 16)
        ],
      ),
    );
  }

  void _showTermsAndCondition(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return IoniaAlertModal(
            title: S.of(context).settings_terms_and_conditions,
            content: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'ioniaPurchaseViewModel.vendor.termsAndConditions',

                ///TODO: implement vendor.termsAndConditions
                style: textMedium(
                  color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                ),
              ),
            ),
            actionTitle: S.of(context).agree,
            showCloseButton: false,
            heightFactor: 0.6,
          );
        });
  }

  Future<void> purchaseCard(BuildContext context) async {
    bool isLogged = await cakePayPurchaseViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      await cakePayPurchaseViewModel.createOrder();
    }
  }

  void _showHowToUseCard(
    BuildContext context,
    CakePayCard card,
  ) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return IoniaAlertModal(
            title: S.of(context).how_to_use_card,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    card.name,
                    style: textLargeSemiBold(
                      color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                    ),
                  )),
              Text(
                card.howToUse ?? '',
                style: textMedium(
                  color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                ),
              )
            ]),
            actionTitle: S.current.got_it,
          );
        });
  }

  Future<void> _showConfirmSendingAlert(BuildContext context) async {
    if (cakePayPurchaseViewModel.order == null) {
      return;
    }

    final order = cakePayPurchaseViewModel.order;

    await showPopUp<void>(
      context: context,
      builder: (_) {
        return ConfirmSendingAlert(
            alertTitle: S.of(context).confirm_sending,
            paymentId: S.of(context).payment_id,
            paymentIdValue: order?.orderId,
            amount: S.of(context).send_amount,
            amountValue: cakePayPurchaseViewModel.sendViewModel.pendingTransaction!.amountFormatted,
            fiatAmountValue:
                cakePayPurchaseViewModel.sendViewModel.pendingTransactionFeeFiatAmountFormatted,
            fee: S.of(context).send_fee,
            feeValue: cakePayPurchaseViewModel.sendViewModel.pendingTransaction!.feeFormatted,
            feeFiatAmount:
                cakePayPurchaseViewModel.sendViewModel.pendingTransactionFeeFiatAmountFormatted,
            feeRate: cakePayPurchaseViewModel.sendViewModel.pendingTransaction!.feeRate,
            outputs: cakePayPurchaseViewModel.sendViewModel.outputs,
            rightButtonText: S.of(context).send,
            leftButtonText: S.of(context).cancel,
            actionRightButton: () async {
              Navigator.of(context).pop();
              await cakePayPurchaseViewModel.commitPaymentInvoice();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }
}

class _PlaceholderContainer extends StatelessWidget {
  const _PlaceholderContainer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).extension<PickerTheme>()!.searchHintColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
          Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
    );
  }
}

class TipButtonGroup extends StatelessWidget {
  const TipButtonGroup({
    Key? key,
    required this.selectedTip,
    required this.onSelect,
    required this.tipsList,
    required this.amount,
    required this.merchant,
  }) : super(key: key);

  final Function(IoniaTip) onSelect;
  final double selectedTip;
  final List<IoniaTip> tipsList;
  final double amount;
  final IoniaMerchant merchant;

  bool _isSelected(double value) => selectedTip == value;

  Set<double> get filter => tipsList.map((e) => e.percentage).toSet();

  bool get _isCustomSelected => !filter.contains(selectedTip);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 50,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tipsList.length,
            itemBuilder: (BuildContext context, int index) {
              final tip = tipsList[index];
              return Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: TipButton(
                    isSelected: tip.isCustom ? _isCustomSelected : _isSelected(tip.percentage),
                    onTap: () async {
                      IoniaTip ioniaTip = tip;
                      if (tip.isCustom) {
                        final customTip = await Navigator.pushNamed(
                            context, Routes.ioniaCustomTipPage,
                            arguments: [amount, merchant, tip]) as IoniaTip?;
                        ioniaTip = customTip ?? tip;
                      }
                      onSelect(ioniaTip);
                    },
                    caption: tip.isCustom
                        ? S.of(context).custom
                        : '${tip.percentage.toStringAsFixed(0)}%',
                    subTitle: tip.isCustom ? null : '\$${tip.additionalAmount.toStringAsFixed(2)}',
                  ));
            }));
  }
}

class TipButton extends StatelessWidget {
  const TipButton({
    required this.caption,
    required this.onTap,
    this.subTitle,
    this.isSelected = false,
  });

  final String caption;
  final String? subTitle;
  final bool isSelected;
  final void Function() onTap;

  bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  Color captionTextColor(BuildContext context) {
    if (isDark(context)) {
      return Theme.of(context).extension<CakeTextTheme>()!.titleColor;
    }

    return isSelected
        ? Theme.of(context).dialogTheme.backgroundColor!
        : Theme.of(context).extension<CakeTextTheme>()!.titleColor;
  }

  Color subTitleTextColor(BuildContext context) {
    if (isDark(context)) {
      return Theme.of(context).extension<CakeTextTheme>()!.titleColor;
    }

    return isSelected
        ? Theme.of(context).dialogTheme.backgroundColor!
        : Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor;
  }

  Color? backgroundColor(BuildContext context) {
    if (isDark(context)) {
      return isSelected
          ? null
          : Theme.of(context).extension<CakeTextTheme>()!.titleColor.withOpacity(0.01);
    }

    return isSelected
        ? null
        : Theme.of(context).extension<CakeTextTheme>()!.titleColor.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 49,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(caption, style: textSmallSemiBold(color: captionTextColor(context))),
            if (subTitle != null) ...[
              SizedBox(height: 4),
              Text(
                subTitle!,
                style: textXxSmallSemiBold(
                  color: subTitleTextColor(context),
                ),
              ),
            ]
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: backgroundColor(context),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
                    Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
      ),
    );
  }
}
