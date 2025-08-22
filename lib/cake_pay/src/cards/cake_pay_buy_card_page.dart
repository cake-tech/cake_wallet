import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_order.dart';
import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_alert_modal.dart';
import 'package:cake_wallet/cake_pay/src/widgets/denominations_amount_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/enter_amount_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/image_placeholder.dart';
import 'package:cake_wallet/cake_pay/src/widgets/link_extractor.dart';
import 'package:cake_wallet/cake_pay/src/widgets/rounded_overlay_cards_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/text_icon_button.dart';
import 'package:cake_wallet/cake_pay/src/widgets/three_checkbox_alert_content_widget.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/address_resolver/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/cake_pay_transaction_sent_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';

class CakePayBuyCardPage extends BasePage {
  CakePayBuyCardPage(
    this.cakePayBuyCardViewModel
  )   : _sendViewModel = cakePayBuyCardViewModel.sendViewModel,
        _amountFieldFocus = FocusNode(),
        _amountController = TextEditingController(),
        _quantityFieldFocus = FocusNode(),
        _quantityController =
            TextEditingController(text: cakePayBuyCardViewModel.quantity.toString()) {
    _amountController.addListener(() {
      cakePayBuyCardViewModel.onAmountChanged(_amountController.text);
    });
  }

  final CakePayBuyCardViewModel cakePayBuyCardViewModel;
  final SendViewModel _sendViewModel;

  bool _effectsInstalled = false;
  late final BuildContext _overlayCtx;

  @override
  String get title => cakePayBuyCardViewModel.card.name;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  bool get gradientAll => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.completelyTransparent;

  @override
  Widget? trailing(BuildContext context) {
    return const SizedBox(
      width: 54,
      height: 0,
    );
  }

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
                    child: card.denominationItems.isNotEmpty
                        ? DenominationsAmountWidget(
                            fiatCurrency: card.fiatCurrency.title,
                            denominations: card.denominationItems,
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
                  padding: const EdgeInsets.only(left: 24, right: 24),
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
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.labelMedium)),
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
              Widget _buildPaymentMethodWidget(
                  List<CakePayPaymentMethod> methods, CakePayPaymentMethod selected) {
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 8),
                      child: Text(
                        'Payment Method',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge!.color!,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(child: const SizedBox()),
                    if (methods.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                        child: ToggleButtons(
                          isSelected: methods.map((m) => m == selected).toList(),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: (index) =>
                              cakePayBuyCardViewModel.chooseMethod(methods[index]),
                          children: methods
                              .map((m) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Text(m.label),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                );
              }

              final methods = cakePayBuyCardViewModel.availableMethods;
              final selected = cakePayBuyCardViewModel.selectedPaymentMethod ??
                  (methods.isNotEmpty ? methods.first : null);

              return Column(
                children: [
                  methods.length <= 1 || selected == null
                      ? const SizedBox.shrink()
                      : _buildPaymentMethodWidget(methods, selected),
                  if (_sendViewModel.walletType == WalletType.litecoin && _sendViewModel.isMwebEnabled)
                    Observer(
                      builder: (_) => Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 0, right: 20, left: 20),
                        child: GestureDetector(
                          key: ValueKey('cake_pay_buy_page_unspent_coin_button_key'),
                          onTap: () {
                            bool value = _sendViewModel.coinTypeToSpendFrom == UnspentCoinType.any;
                            _sendViewModel.setAllowMwebCoins(!value);
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StandardCheckbox(
                                  caption: S.of(context).litecoin_mweb_allow_coins,
                                  captionColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                  borderColor: Theme.of(context).colorScheme.primary,
                                  iconColor: Theme.of(context).colorScheme.primary,
                                  value:
                                  _sendViewModel.coinTypeToSpendFrom == UnspentCoinType.any,
                                  onChanged: (bool? value) {
                                    _sendViewModel.setAllowMwebCoins(value ?? false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (FeatureFlag.hasDevOptions && FeatureFlag.isCakePayPurchaseSimulationEnabled)
                    Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 0, right: 20, left: 20),
                      child: LoadingPrimaryButton(
                        onPressed: () {
                          //Request dummy node to get the focus out of the text fields
                          FocusScope.of(context).requestFocus(FocusNode());

                          cakePayBuyCardViewModel.isSimulatingFlow = true;
                          isIOSUnavailable(card)
                              ? alertIOSAvailability(context, card)
                              : confirmPurchaseFirst(context);
                        },
                        text: '(Dev) Simulate Purchasing Gift Card',
                        isDisabled: !cakePayBuyCardViewModel.isAmountSufficient ||
                            cakePayBuyCardViewModel.isPurchasing,
                        isLoading:
                        _sendViewModel.state is IsExecutingState ||
                                cakePayBuyCardViewModel.isPurchasing,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  Padding(
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
                      isLoading: _sendViewModel.state is IsExecutingState ||
                          cakePayBuyCardViewModel.isPurchasing,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
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
    cakePayBuyCardViewModel.isSimulatingFlow = false;
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
    bool isLogged = await cakePayBuyCardViewModel.isUserLogged;
    if (!isLogged) {
      cakePayBuyCardViewModel.isSimulatingFlow = false;
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
            cakePayBuyCardViewModel.isSimulatingFlow = false;
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
    } else {
      cakePayBuyCardViewModel.isPurchasing = false;
      cakePayBuyCardViewModel.isSimulatingFlow = false;
    }
  }

  Future<void> purchaseCard(BuildContext context) async {
    bool isLogged = await cakePayBuyCardViewModel.isUserLogged;
    if (!isLogged) {
      cakePayBuyCardViewModel.isSimulatingFlow = false;
      Navigator.of(context).pushNamed(Routes.cakePayWelcomePage);
    } else {
      try {
        await cakePayBuyCardViewModel.createOrder();
      } catch (_) {
        cakePayBuyCardViewModel.isSimulatingFlow = false;
        await cakePayBuyCardViewModel.logout();
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

    _overlayCtx = Navigator.of(context).context;

    if (_sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(_sendViewModel.wallet);
    }

    reaction((_) => _sendViewModel.state, (ExecutionState state) async {
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
        final currentState = _sendViewModel.state;
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
            _sendViewModel.state = FailureState('Order expired');
            disposer?.call();
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            final order = cakePayBuyCardViewModel.order;

            final displayingOutputs = _sendViewModel.outputs
                .map((o) => o.OutputCopyWithParsedAddress(
                      parsedAddress: ParsedAddress(
                        parsedAddressByCurrencyMap: {
                          cakePayBuyCardViewModel.sendViewModel.selectedCryptoCurrency:
                              o.address,
                        },
                        handle: 'Cake Pay',
                        profileName: order?.cards.first.cardName ?? 'Cake Pay',
                        profileImageUrl: order?.cards.first.cardImagePath ?? '',
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
                  walletType: _sendViewModel.walletType,
                  titleIconPath: _sendViewModel.selectedCryptoCurrency.iconPath,
                  currency: _sendViewModel.selectedCryptoCurrency,
                  amount: S.of(bottomSheetContext).send_amount,
                  amountValue: _sendViewModel.pendingTransaction!.amountFormatted,
                  quantity: 'QTY: ${cakePayBuyCardViewModel.quantity}',
                  fiatAmountValue: _sendViewModel.pendingTransactionFiatAmountFormatted,
                  fee: S.of(bottomSheetContext).send_fee,
                  feeValue: _sendViewModel.pendingTransaction!.feeFormatted,
                  feeFiatAmount:_sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                  outputs: displayingOutputs,
                  footerType: FooterType.slideActionButton,
                  slideActionButtonText:
                      cakePayBuyCardViewModel.isSimulating ? 'Swipe to simulate' : 'Swipe to send',
                  accessibleNavigationModeSlideActionButtonText:
                      cakePayBuyCardViewModel.isSimulating ? 'Simulate' : S.of(context).send,
                  onSlideActionComplete: () async {
                    Navigator.of(bottomSheetContext).pop(true);
                    cakePayBuyCardViewModel.isSimulating
                        ? cakePayBuyCardViewModel.simulatePayment()
                        : _sendViewModel.commitTransaction(context);
                  },
                  change: _sendViewModel.pendingTransaction!.change,
                  isOpenCryptoPay: _sendViewModel.ocpRequest != null,
                );
              },
            );

            confirmBottomSheetContext = null;
            cakePayBuyCardViewModel.isSimulatingFlow = false;
            _handleDispose(disposer);
            if (result == null) _sendViewModel.dismissTransaction();
          }
        });
      }

      if (state is TransactionCommitted) {
        final order = cakePayBuyCardViewModel.order;
        final outputsCopy = List<Output>.from(_sendViewModel.outputs);

        final displayingOutputs = outputsCopy
            .map((o) => o.OutputCopyWithParsedAddress(
                  parsedAddress: ParsedAddress(
                    handle: 'Cake Pay',
                    profileName: order?.cards.first.cardName ?? 'Cake Pay',
                    profileImageUrl: order?.cards.first.cardImagePath ?? '', parsedAddressByCurrencyMap: {
                      cakePayBuyCardViewModel.sendViewModel.selectedCryptoCurrency:
                          o.address,
                    },
                  ),
                  fiatAmount: '${order?.amountUsd ?? 0} USD',
                ))
            .toList();

        _sendViewModel.clearOutputs();

        final bool usePageContextLater = context.mounted;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (displayingOutputs.isEmpty) {
            if (context.mounted) Navigator.of(context).pop();
            return;
          }

          final BuildContext sheetParentCtx = usePageContextLater ? context : _overlayCtx;

          await showModalBottomSheet<void>(
            context: sheetParentCtx,
            useRootNavigator: !usePageContextLater,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.transparent,
            builder: (sheetCtx) {
              return CakePayTransactionSentBottomSheet(
                key: const ValueKey('cake_pay_buy_page_transaction_sent_bottom_sheet_key'),
                titleText: S.of(sheetCtx).transaction_sent,
                titleIconWidget: const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
                output: displayingOutputs.first,
                currency: _sendViewModel.selectedCryptoCurrency,
                amount: S.of(sheetCtx).send_amount,
                amountValue: _sendViewModel.pendingTransaction!.amountFormatted,
                quantity: 'QTY: ${cakePayBuyCardViewModel.quantity}',
                fiatAmountValue: _sendViewModel.pendingTransactionFiatAmountFormatted,
                fee: S.of(sheetCtx).send_fee,
                feeValue: _sendViewModel.pendingTransaction!.feeFormatted,
                feeFiatAmount: _sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                paymentId: 'Order ID',
                paymentIdValue: order?.orderId ?? '',
                onClose: () {
                  Navigator.of(sheetCtx).pop();
                },
              );
            },
          );
          if (context.mounted) {
            Navigator.of(context).pop();
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
                _sendViewModel.state = InitialExecutionState();
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
          dismissible: true,
          content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
                padding: EdgeInsets.all(10),
                child: Text(card.name, style: Theme.of(context).textTheme.headlineSmall)),
            ClickableLinksText(
                text: card.howToUse ?? '',
                textStyle: Theme.of(context).textTheme.bodyMedium!,
                linkStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic))
          ]),
          actionTitle: S.current.got_it,
          showCloseButton: false,
        );
      });
}

void _showTermsAndCondition(BuildContext context, String? termsAndConditions) {
  showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return CakePayAlertModal(
          title: S.of(context).settings_terms_and_conditions,
          dismissible: true,
          content: Align(
              alignment: Alignment.bottomLeft,
              child: ClickableLinksText(
                  text: termsAndConditions ?? '',
                  textStyle: Theme.of(context).textTheme.bodyMedium!,
                  linkStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic))),
          actionTitle: S.of(context).agree,
          showCloseButton: false,
        );
      });
}
