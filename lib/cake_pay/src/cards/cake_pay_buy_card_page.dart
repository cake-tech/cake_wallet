import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/cake_pay/src/widgets/denominations_amount_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/enter_amount_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/image_placeholder.dart';
import 'package:cake_wallet/cake_pay/src/widgets/link_extractor.dart';
import 'package:cake_wallet/cake_pay/src/widgets/rounded_overlay_cards_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/text_icon_button.dart';
import 'package:cake_wallet/cake_pay/src/widgets/three_checkbox_alert_content_widget.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';

class CakePayBuyCardPage extends BasePage {
  CakePayBuyCardPage(
    this.cakePayBuyCardViewModel,
    this.cakePayService,
  )   : _amountFieldFocus = FocusNode(),
        _amountController = TextEditingController(),
        _quantityFieldFocus = FocusNode(),
        _quantityController =
            TextEditingController(text: cakePayBuyCardViewModel.quantity.toString()) {
    _amountController.addListener(() {
      cakePayBuyCardViewModel.onAmountChanged(_amountController.text);
    });
  }

  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final CakePayService cakePayService;

  bool _effectsInstalled = false;

  @override
  String get title => cakePayBuyCardViewModel.card.name;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  bool get gradientAll => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.completelyTransparent;

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

  final TextEditingController _amountController;
  final FocusNode _amountFieldFocus;
  final TextEditingController _quantityController;
  final FocusNode _quantityFieldFocus;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    final card = cakePayBuyCardViewModel.card;
    final vendor = cakePayBuyCardViewModel.vendor;
    final baseTitleColor = titleColor(context);

    return KeyboardActions(
      disableScroll: true,
      config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: Theme.of(context).primaryColor,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
              focusNode: _amountFieldFocus,
              toolbarButtons: [(_) => KeyboardDoneButton()],
            ),
          ]),
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            RoundedOverlayCards(
                topCardChild: Column(
                  children: [
                    Expanded(flex: 4, child: const SizedBox()),
                    Expanded(
                      flex: 7,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withAlpha(150),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
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
                        ),
                      ),
                    ),
                    Expanded(child: const SizedBox()),
                  ],
                ),
                bottomCardChild: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: card.denominations.isNotEmpty
                        ? DenominationsAmountWidget(
                            fiatCurrency: card.fiatCurrency.title,
                            denominations: card.denominations,
                            amountFieldFocus: _amountFieldFocus,
                            amountController: _amountController,
                            quantityFieldFocus: _quantityFieldFocus,
                            quantityController: _quantityController,
                            onAmountChanged: cakePayBuyCardViewModel.onAmountChanged,
                            onQuantityChanged: cakePayBuyCardViewModel.onQuantityChanged,
                            cakePayBuyCardViewModel: cakePayBuyCardViewModel)
                        : EnterAmountWidget(
                            minValue: card.minValue ?? '-',
                            maxValue: card.maxValue ?? '-',
                            fiatCurrency: card.fiatCurrency.title,
                            amountFieldFocus: _amountFieldFocus,
                            amountController: _amountController,
                            onAmountChanged: cakePayBuyCardViewModel.onAmountChanged))),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vendor.cakeWarnings != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withAlpha(50)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                vendor.cakeWarnings!,
                                textAlign: TextAlign.center,
                                style: textSmallSemiBold(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        primary: false,
                        padding: EdgeInsets.zero,
                        child: ClickableLinksText(
                          text: card.description ?? '',
                          textStyle: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge!.color!,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 38, right: 24),
                  child: Column(
                    children: [
                      if (card.expiryAndValidity != null && card.expiryAndValidity!.isNotEmpty)
                        Row(
                          children: [
                            Text(S.of(context).expiry_and_validity + ':',
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.titleLarge!.color!,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            Expanded(
                                child: Text(card.expiryAndValidity!,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                        color: Theme.of(context).textTheme.titleLarge!.color!,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400))),
                          ],
                        ),
                      SizedBox(height: 8),
                      TextIconButton(
                          label: S.of(context).how_to_use_card,
                          onTap: () => _showHowToUseCard(context, card)),
                      SizedBox(height: 8),
                      TextIconButton(
                          label: S.of(context).settings_terms_and_conditions,
                          onTap: () => _showTermsAndCondition(context, card.termsAndConditions)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Observer(builder: (_) {
              return Padding(
                padding: EdgeInsets.only(top: 10, bottom: 34, right: 20, left: 20),
                child: LoadingPrimaryButton(
                  onPressed: () {
                    //Request dummy node to get the focus out of the text fields
                    FocusScope.of(context).requestFocus(FocusNode());

                    isIOSUnavailable(card)
                        ? alertIOSAvailability(context, card)
                        : confirmPurchaseFirst(context);
                  },
                  text: S.of(context).purchase_gift_card,
                  isDisabled: !cakePayBuyCardViewModel.isAmountSufficient ||
                      cakePayBuyCardViewModel.isPurchasing,
                  isLoading: cakePayBuyCardViewModel.sendViewModel.state is IsExecutingState ||
                      cakePayBuyCardViewModel.isPurchasing,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool isWordInCardsName(CakePayCard card, String word) {
    return card.name.toLowerCase().contains(word.toLowerCase());
  }

  bool isIOSUnavailable(CakePayCard card) {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return false;
    }

    final isDigitalGameStores = isWordInCardsName(card, 'playstation') ||
        isWordInCardsName(card, 'xbox') ||
        isWordInCardsName(card, 'steam') ||
        isWordInCardsName(card, 'meta quest') ||
        isWordInCardsName(card, 'kigso') ||
        isWordInCardsName(card, 'game world') ||
        isWordInCardsName(card, 'google') ||
        isWordInCardsName(card, 'nintendo');
    final isGCodes = isWordInCardsName(card, 'gcodes');
    final isApple = isWordInCardsName(card, 'itunes') || isWordInCardsName(card, 'apple');
    final isTidal = isWordInCardsName(card, 'tidal');
    final isVPNServices = isWordInCardsName(card, 'nordvpn') ||
        isWordInCardsName(card, 'expressvpn') ||
        isWordInCardsName(card, 'surfshark') ||
        isWordInCardsName(card, 'proton');
    final isStreamingServices = isWordInCardsName(card, 'netflix') ||
        isWordInCardsName(card, 'spotify') ||
        isWordInCardsName(card, 'hulu') ||
        isWordInCardsName(card, 'hbo') ||
        isWordInCardsName(card, 'soundcloud') ||
        isWordInCardsName(card, 'twitch');
    final isDatingServices = isWordInCardsName(card, 'tinder');

    return isDigitalGameStores ||
        isGCodes ||
        isApple ||
        isTidal ||
        isVPNServices ||
        isStreamingServices ||
        isDatingServices;
  }

  Future<void> alertIOSAvailability(BuildContext context, CakePayCard card) async {
    return await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.of(context).error,
              alertContent: S.of(context).cakepay_ios_not_available,
              buttonText: S.of(context).ok,
              buttonAction: () {
                // _walletHardwareRestoreVM.error = null;
                Navigator.of(context).pop();
              });
        });
  }

  Future<void> confirmPurchaseFirst(BuildContext context) async {
    bool isLogged = await cakePayBuyCardViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      cakePayBuyCardViewModel.isPurchasing = true;
      await _showconfirmPurchaseFirstAlert(context);
    }
  }

  Future<void> _showconfirmPurchaseFirstAlert(BuildContext context) async {
    if (!cakePayBuyCardViewModel.confirmsNoVpn ||
        !cakePayBuyCardViewModel.confirmsVoidedRefund ||
        !cakePayBuyCardViewModel.confirmsTermsAgreed) {
      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => ThreeCheckboxAlert(
          alertTitle: S.of(context).cakepay_confirm_purchase,
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).confirm,
          actionLeftButton: () {
            cakePayBuyCardViewModel.isPurchasing = false;
            Navigator.of(context).pop();
          },
          actionRightButton: (confirmsNoVpn, confirmsVoidedRefund, confirmsTermsAgreed) {
            cakePayBuyCardViewModel.confirmsNoVpn = confirmsNoVpn;
            cakePayBuyCardViewModel.confirmsVoidedRefund = confirmsVoidedRefund;
            cakePayBuyCardViewModel.confirmsTermsAgreed = confirmsTermsAgreed;

            Navigator.of(context).pop();
          },
        ),
      );
    }

    if (cakePayBuyCardViewModel.confirmsNoVpn &&
        cakePayBuyCardViewModel.confirmsVoidedRefund &&
        cakePayBuyCardViewModel.confirmsTermsAgreed) {
      await purchaseCard(context);
    }
  }

  Future<void> purchaseCard(BuildContext context) async {
    bool isLogged = await cakePayBuyCardViewModel.cakePayService.isLogged();
    if (!isLogged) {
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      try {
        await cakePayBuyCardViewModel.createOrder();
      } catch (_) {
        await cakePayBuyCardViewModel.cakePayService.logout();
      }
    }
    cakePayBuyCardViewModel.isPurchasing = false;
  }

  BuildContext? dialogContext;
  BuildContext? loadingBottomSheetContext;
  BuildContext? confirmBottomSheetContext;

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    if (cakePayBuyCardViewModel.sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(cakePayBuyCardViewModel.sendViewModel.wallet);
    }

    reaction((_) => cakePayBuyCardViewModel.sendViewModel.state, (ExecutionState state) async {
      if (dialogContext != null && dialogContext!.mounted) Navigator.of(dialogContext!).pop();

      if (confirmBottomSheetContext != null && confirmBottomSheetContext!.mounted) {
        Navigator.of(confirmBottomSheetContext!).pop();
      }

      if (state is! IsExecutingState &&
          loadingBottomSheetContext != null &&
          loadingBottomSheetContext!.mounted) {
        Navigator.of(loadingBottomSheetContext!).pop();
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted)
            showPopUp<void>(
                context: context,
                builder: (BuildContext context) {
                  return AlertWithOneAction(
                      key: ValueKey('cake_pay_buy_page_send_failure_dialog_key'),
                      buttonKey: ValueKey('cake_pay_buy_page_send_failure_dialog_button_key'),
                      alertTitle: S.of(context).error,
                      alertContent: state.error,
                      buttonText: S.of(context).ok,
                      buttonAction: () => Navigator.of(context).pop());
                });
        });
      }

      if (state is IsExecutingState) {
        // wait a bit to avoid showing the loading dialog if transaction is failed
        await Future.delayed(const Duration(milliseconds: 300));
        final currentState = cakePayBuyCardViewModel.sendViewModel.state;
        if (currentState is ExecutedSuccessfullyState || currentState is FailureState) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (BuildContext context) {
                loadingBottomSheetContext = context;
                return LoadingBottomSheet(
                  titleText: S.of(context).generating_transaction,
                );
              },
            );
          }
        });
      }

      if (state is ExecutedSuccessfullyState) {
        if (cakePayBuyCardViewModel.order == null) return;

        ReactionDisposer? disposer;

        disposer = reaction((_) => cakePayBuyCardViewModel.isOrderExpired, (bool isExpired) {
          if (isExpired) {
            cakePayBuyCardViewModel.sendViewModel.state = FailureState('Order expired');
            disposer?.call();
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            final order = cakePayBuyCardViewModel.order;

            final displayingOutputs = cakePayBuyCardViewModel.sendViewModel.outputs
                .map((o) => o.OutputCopyWithParsedAddress(
                      parsedAddress: ParsedAddress(
                        addresses: [o.address],
                        name: 'Cake Pay',
                        profileName: order?.cardName ?? 'Cake Pay',
                        profileImageUrl: order?.cardImagePath ?? '',
                      ),
                      fiatAmount: '${order?.amountUsd.toString()} USD',
                    ))
                .toList();

            final result = await showModalBottomSheet<bool>(
              context: context,
              isDismissible: false,
              isScrollControlled: true,
              builder: (BuildContext bottomSheetContext) {
                confirmBottomSheetContext = bottomSheetContext;
                return ConfirmSendingBottomSheet(
                  key: ValueKey('cake_pay_buy_page_confirm_sending_dialog_key'),
                  titleText: S.of(bottomSheetContext).confirm_transaction,
                  currentTheme: currentTheme,
                  cakePayBuyCardViewModel: cakePayBuyCardViewModel,
                  paymentId: S.of(bottomSheetContext).payment_id,
                  paymentIdValue: cakePayBuyCardViewModel.order?.orderId,
                  expirationTime: cakePayBuyCardViewModel.formattedRemainingTime,
                  walletType: cakePayBuyCardViewModel.sendViewModel.walletType,
                  titleIconPath:
                      cakePayBuyCardViewModel.sendViewModel.selectedCryptoCurrency.iconPath,
                  currency: cakePayBuyCardViewModel.sendViewModel.selectedCryptoCurrency,
                  amount: S.of(bottomSheetContext).send_amount,
                  amountValue:
                      cakePayBuyCardViewModel.sendViewModel.pendingTransaction!.amountFormatted,
                  quantity: 'QTY: ${order?.cards.length.toString()}',
                  fiatAmountValue:
                      cakePayBuyCardViewModel.sendViewModel.pendingTransactionFiatAmountFormatted,
                  fee: S.of(bottomSheetContext).send_fee,
                  feeValue: cakePayBuyCardViewModel.sendViewModel.pendingTransaction!.feeFormatted,
                  feeFiatAmount: cakePayBuyCardViewModel
                      .sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                  outputs: displayingOutputs,
                  footerType: FooterType.slideActionButton,
                  slideActionButtonText: 'Swipe to send',
                  accessibleNavigationModeSlideActionButtonText: S.of(context).send,
                  onSlideActionComplete: () async {
                    Navigator.of(bottomSheetContext).pop(true);
                    FeatureFlag.hasDevOptions
                        ? cakePayBuyCardViewModel.simulatePayment()
                        : cakePayBuyCardViewModel.sendViewModel.commitTransaction(context);
                  },
                  change: cakePayBuyCardViewModel.sendViewModel.pendingTransaction!.change,
                  isOpenCryptoPay: cakePayBuyCardViewModel.sendViewModel.ocpRequest != null,
                );
              },
            );

            confirmBottomSheetContext = null;
            _handleDispose(disposer);
            if (result == null) cakePayBuyCardViewModel.sendViewModel.dismissTransaction();
          }
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          cakePayBuyCardViewModel.sendViewModel.clearOutputs();

          if (!context.mounted) return;

          final isCopy = await showModalBottomSheet<bool>(
                  context: context,
                  isDismissible: false,
                  builder: (BuildContext bottomSheetContext) {
                    return InfoBottomSheet(
                      currentTheme: currentTheme,
                      footerType: FooterType.doubleActionButton,
                      rightActionButtonKey:
                          ValueKey('cake_pay_buy_page_sent_dialog_copy_button_key'),
                      doubleActionRightButtonText: S.of(bottomSheetContext).copy,
                      onRightActionButtonPressed: () {
                        Navigator.of(bottomSheetContext).pop(true);
                      },
                      leftActionButtonKey: ValueKey('cake_pay_buy_page_sent_dialog_ok_button_key'),
                      doubleActionLeftButtonText: S.of(bottomSheetContext).close,
                      onLeftActionButtonPressed: () => Navigator.of(bottomSheetContext).pop(false),
                      titleText: S.of(bottomSheetContext).transaction_sent,
                      contentImage: cakePayBuyCardViewModel.order!.cardImagePath,
                      bottomActionPanel: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Column(
                          children: [
                            Text(
                              textAlign: TextAlign.center,
                              FeatureFlag.hasDevOptions
                                  ? cakePayBuyCardViewModel.simulatedResponse
                                  : S.of(bottomSheetContext).cake_pay_save_order,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.titleLarge!.color!,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(cakePayBuyCardViewModel.order!.orderId,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.titleLarge!.color!,
                                  decoration: TextDecoration.none,
                                )),
                          ],
                        ),
                      ),
                    );
                  }) ??
              false;

          if (isCopy) {
            await Clipboard.setData(ClipboardData(text: cakePayBuyCardViewModel.order!.orderId));
          }
        });
      }

      if (state is IsAwaitingDeviceResponseState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (BuildContext bottomSheetContext) => InfoBottomSheet(
              currentTheme: currentTheme,
              footerType: FooterType.singleActionButton,
              titleText: S.of(bottomSheetContext).proceed_on_device,
              contentImage: 'assets/images/hardware_wallet/ledger_nano_x.png',
              contentImageColor: Theme.of(context).textTheme.titleLarge!.color!,
              content: S.of(bottomSheetContext).proceed_on_device_description,
              singleActionButtonText: S.of(context).cancel,
              onSingleActionButtonPressed: () {
                cakePayBuyCardViewModel.sendViewModel.state = InitialExecutionState();
                Navigator.of(bottomSheetContext).pop();
              },
            ),
          );
        });
      }
    });

    _effectsInstalled = true;
  }

  void _handleDispose(ReactionDisposer? disposer) {
    cakePayBuyCardViewModel.dispose();
    if (disposer != null) {
      disposer();
    }
  }
}

void _showHowToUseCard(BuildContext context, CakePayCard card) {
  showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return CakePayAlertModal(
          title: S.of(context).how_to_use_card,
          content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: EdgeInsets.all(10),
                child: Text(card.name, style: Theme.of(context).textTheme.headlineSmall)),
            ClickableLinksText(
              text: card.howToUse ?? '',
              textStyle: Theme.of(context).textTheme.bodyMedium!,
              linkStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ]),
          actionTitle: S.current.got_it,
        );
      });
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
                textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
              )),
          actionTitle: S.of(context).agree,
          showCloseButton: false,
          heightFactor: 0.6,
        );
      });
}
