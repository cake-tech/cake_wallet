import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/image_placeholder.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/link_extractor.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_purchase_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class CakePayBuyCardDetailPage extends BasePage {
  CakePayBuyCardDetailPage(this.cakePayPurchaseViewModel);

  final CakePayPurchaseViewModel cakePayPurchaseViewModel;

  @override
  String get title => cakePayPurchaseViewModel.card.name;

  @override
  Widget? middle(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
          color: titleColor(context)),
    );
  }

  @override
  Widget? trailing(BuildContext context) => null;

  bool _effectsInstalled = false;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    final card = cakePayPurchaseViewModel.card;

    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.zero,
      content: Observer(builder: (_) {
        return Column(
          children: [
            SizedBox(height: 36),
            ClipRRect(
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),
                child: Row(
                  children: [
                    Expanded(
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
                              CakePayCardImagePlaceholder(),
                        ),
                      )),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(children: [
                          Row(
                            children: [
                              Text(
                                S.of(context).value + ':',
                                style: textLarge(
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${cakePayPurchaseViewModel.amount.toStringAsFixed(2)} ${cakePayPurchaseViewModel.fiatCurrency}',
                                style: textLarge(
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                S.of(context).quantity + ':',
                                style: textLarge(
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${cakePayPurchaseViewModel.quantity}',
                                style: textLarge(
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                S.of(context).total + ':',
                                style: textLarge(
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${cakePayPurchaseViewModel.totalAmount.toStringAsFixed(2)} ${cakePayPurchaseViewModel.fiatCurrency}',
                                style: textLarge(
                                    color:
                                        Theme.of(context).extension<CakeTextTheme>()!.titleColor),
                              ),
                            ],
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
            SizedBox(height: 20),
            if (card.expiryAndValidity != null && card.expiryAndValidity!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.of(context).expiry_and_validity + ':',
                        style: textMediumSemiBold(
                            color: Theme.of(context).extension<CakeTextTheme>()!.titleColor)),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          card.expiryAndValidity ?? '',
                          style: textMedium(
                            color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                isDisabled: cakePayPurchaseViewModel.isPurchasing,
                isLoading: cakePayPurchaseViewModel.isPurchasing ||
                    cakePayPurchaseViewModel.sendViewModel.state is IsExecutingState,
                onPressed: () => confirmPurchaseFirst(context),
                text: S.of(context).purchase_gift_card,
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
              );
            }),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () => _showTermsAndCondition(context, card.termsAndConditions),
            child: Text(S.of(context).settings_terms_and_conditions,
                style: textMediumSemiBold(
                  color: Theme.of(context).primaryColor,
                ).copyWith(fontSize: 12)),
          ),
          SizedBox(height: 16)
        ],
      ),
    );
  }

  void _showTermsAndCondition(BuildContext context, String? termsAndConditions) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return CakePayAlertModal(
            title: S.of(context).settings_terms_and_conditions,
            content: Align(
              alignment: Alignment.bottomLeft,
              child: ClickableLinksText(
                text: termsAndConditions ?? '',
                textStyle: TextStyle(
                  color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            actionTitle: S.of(context).agree,
            showCloseButton: false,
            heightFactor: 0.6,
          );
        });
  }

  Future<void> _showconfirmPurchaseFirstAlert(BuildContext context) async {
    if (!cakePayPurchaseViewModel.confirmsNoVpn ||
        !cakePayPurchaseViewModel.confirmsVoidedRefund ||
        !cakePayPurchaseViewModel.confirmsTermsAgreed) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => ThreeCheckboxAlert(
          alertTitle: S.of(context).cakepay_confirm_purchase,
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).confirm,
          actionLeftButton: () {
            cakePayPurchaseViewModel.isPurchasing = false;
            Navigator.of(context).pop();
          },
          actionRightButton: (confirmsNoVpn, confirmsVoidedRefund, confirmsTermsAgreed) {
            cakePayPurchaseViewModel.confirmsNoVpn = confirmsNoVpn;
            cakePayPurchaseViewModel.confirmsVoidedRefund = confirmsVoidedRefund;
            cakePayPurchaseViewModel.confirmsTermsAgreed = confirmsTermsAgreed;

            Navigator.of(context).pop();
          },
        ),
      );
    }

    if (cakePayPurchaseViewModel.confirmsNoVpn &&
        cakePayPurchaseViewModel.confirmsVoidedRefund &&
        cakePayPurchaseViewModel.confirmsTermsAgreed) {
      await purchaseCard(context);
    }
  }

  Future<void> confirmPurchaseFirst(BuildContext context) async {
    bool isLogged = await cakePayPurchaseViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      cakePayPurchaseViewModel.isPurchasing = true;
      await _showconfirmPurchaseFirstAlert(context);
    }
  }

  Future<void> purchaseCard(BuildContext context) async {
    bool isLogged = await cakePayPurchaseViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      try {
        await cakePayPurchaseViewModel.createOrder();
      } catch (_) {
        await cakePayPurchaseViewModel.cakePayService.logout();
      }

   }
   cakePayPurchaseViewModel.isPurchasing = false;
  }

  void _showHowToUseCard(
    BuildContext context,
    CakePayCard card,
  ) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return CakePayAlertModal(
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
              ClickableLinksText(
                text: card.howToUse ?? '',
                textStyle: TextStyle(
                  color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                linkStyle: TextStyle(
                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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

  Future<void> _showConfirmSendingAlert(BuildContext context) async {
    if (cakePayPurchaseViewModel.order == null) {
      return;
    }
    ReactionDisposer? disposer;

    disposer = reaction((_) => cakePayPurchaseViewModel.isOrderExpired, (bool isExpired) {
      if (isExpired) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (disposer != null) {
          disposer();
        }
      }
    });

    final order = cakePayPurchaseViewModel.order;
    final pendingTransaction = cakePayPurchaseViewModel.sendViewModel.pendingTransaction!;

    await showPopUp<void>(
      context: context,
      builder: (popupContext) {
        return Observer(
            builder: (_) => ConfirmSendingAlert(
                alertTitle: S.of(popupContext).confirm_sending,
                paymentId: S.of(popupContext).payment_id,
                paymentIdValue: order?.orderId,
                expirationTime: cakePayPurchaseViewModel.formattedRemainingTime,
                onDispose: () => _handleDispose(disposer),
                amount: S.of(popupContext).send_amount,
                amountValue: pendingTransaction.amountFormatted,
                fiatAmountValue:
                    cakePayPurchaseViewModel.sendViewModel.pendingTransactionFiatAmountFormatted,
                fee: S.of(popupContext).send_fee,
                feeValue: pendingTransaction.feeFormatted,
                feeFiatAmount:
                    cakePayPurchaseViewModel.sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                feeRate: pendingTransaction.feeRate,
                outputs: cakePayPurchaseViewModel.sendViewModel.outputs,
                rightButtonText: S.of(popupContext).send,
                leftButtonText: S.of(popupContext).cancel,
                actionRightButton: () async {
                  Navigator.of(context).pop();
                  await cakePayPurchaseViewModel.sendViewModel.commitTransaction(context);
                },
                actionLeftButton: () => Navigator.of(popupContext).pop()));
      },
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => cakePayPurchaseViewModel.sendViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showStateAlert(context, S.of(context).error, state.error);
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _showConfirmSendingAlert(context);
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cakePayPurchaseViewModel.sendViewModel.clearOutputs();
          if (context.mounted) showSentAlert(context);
        });
      }
    });

    _effectsInstalled = true;
  }

  void showStateAlert(BuildContext context, String title, String content) {
    if (context.mounted) {
      showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: title,
                alertContent: content,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    }
  }

  Future<void> showSentAlert(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    final order = cakePayPurchaseViewModel.order!.orderId;
    final isCopy = await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).transaction_sent,
                  alertContent: S.of(context).cake_pay_save_order + '\n${order}',
                  leftButtonText: S.of(context).ignor,
                  rightButtonText: S.of(context).copy,
                  actionLeftButton: () => Navigator.of(context).pop(false),
                  actionRightButton: () => Navigator.of(context).pop(true));
            }) ??
        false;

    if (isCopy) {
      await Clipboard.setData(ClipboardData(text: order));
    }
  }

  void _handleDispose(ReactionDisposer? disposer) {
    cakePayPurchaseViewModel.dispose();
    if (disposer != null) {
      disposer();
    }
  }
}

class ThreeCheckboxAlert extends BaseAlertDialog {
  ThreeCheckboxAlert({
    required this.alertTitle,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    this.alertBarrierDismissible = true,
    Key? key,
  });

  final String alertTitle;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final Function(bool, bool, bool) actionRightButton;
  final bool alertBarrierDismissible;

  bool checkbox1 = false;
  void toggleCheckbox1() => checkbox1 = !checkbox1;
  bool checkbox2 = false;
  void toggleCheckbox2() => checkbox2 = !checkbox2;
  bool checkbox3 = false;
  void toggleCheckbox3() => checkbox3 = !checkbox3;

  bool showValidationMessage = true;

  @override
  String get titleText => alertTitle;

  @override
  bool get isDividerExists => true;

  @override
  String get leftActionButtonText => leftButtonText;

  @override
  String get rightActionButtonText => rightButtonText;

  @override
  VoidCallback get actionLeft => actionLeftButton;

  @override
  VoidCallback get actionRight => () {
        actionRightButton(checkbox1, checkbox2, checkbox3);
      };

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  Widget content(BuildContext context) {
    return ThreeCheckboxAlertContent(
      checkbox1: checkbox1,
      toggleCheckbox1: toggleCheckbox1,
      checkbox2: checkbox2,
      toggleCheckbox2: toggleCheckbox2,
      checkbox3: checkbox3,
      toggleCheckbox3: toggleCheckbox3,
    );
  }
}

class ThreeCheckboxAlertContent extends StatefulWidget {
  ThreeCheckboxAlertContent({
    required this.checkbox1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.toggleCheckbox2,
    required this.checkbox3,
    required this.toggleCheckbox3,
    Key? key,
  }) : super(key: key);

  bool checkbox1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  void Function() toggleCheckbox2;
  bool checkbox3;
  void Function() toggleCheckbox3;

  @override
  _ThreeCheckboxAlertContentState createState() => _ThreeCheckboxAlertContentState(
        checkbox1: checkbox1,
        toggleCheckbox1: toggleCheckbox1,
        checkbox2: checkbox2,
        toggleCheckbox2: toggleCheckbox2,
        checkbox3: checkbox3,
        toggleCheckbox3: toggleCheckbox3,
      );

  static _ThreeCheckboxAlertContentState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ThreeCheckboxAlertContentState>();
  }
}

class _ThreeCheckboxAlertContentState extends State<ThreeCheckboxAlertContent> {
  _ThreeCheckboxAlertContentState({
    required this.checkbox1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.toggleCheckbox2,
    required this.checkbox3,
    required this.toggleCheckbox3,
  });

  bool checkbox1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  void Function() toggleCheckbox2;
  bool checkbox3;
  void Function() toggleCheckbox3;

  bool showValidationMessage = true;

  bool get areAllCheckboxesChecked => checkbox1 && checkbox2 && checkbox3;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StandardCheckbox(
            value: checkbox1,
            caption: S.of(context).cakepay_confirm_no_vpn,
            onChanged: (bool? value) {
              setState(() {
                checkbox1 = value ?? false;
                toggleCheckbox1();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          StandardCheckbox(
            value: checkbox2,
            caption: S.of(context).cakepay_confirm_voided_refund,
            onChanged: (bool? value) {
              setState(() {
                checkbox2 = value ?? false;
                toggleCheckbox2();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          StandardCheckbox(
            value: checkbox3,
            caption: S.of(context).cakepay_confirm_terms_agreed,
            onChanged: (bool? value) {
              setState(() {
                checkbox3 = value ?? false;
                toggleCheckbox3();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => launchUrl(
              Uri.parse("https://cakepay.com/cakepay-web-terms.txt"),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                S.of(context).settings_terms_and_conditions,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.none,
                  height: 1,
                ),
                softWrap: true,
              ),
            ),
          ),
          if (showValidationMessage)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Please confirm all checkboxes',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
