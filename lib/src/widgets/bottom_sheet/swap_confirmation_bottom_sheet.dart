import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/debounce.dart';

import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cake_wallet/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:mobx/mobx.dart';

class SwapConfirmationBottomSheet extends BaseBottomSheet {
  SwapConfirmationBottomSheet({
    Key? key,
    required this.paymentFlowResult,
    required this.currentTheme,
    required this.exchangeViewModel,
    required this.authService,
  }) : super(
          titleText: S.current.swap,
          footerType: FooterType.none,
          maxHeight: 900,
          currentTheme: currentTheme,
        );

  final PaymentFlowResult paymentFlowResult;
  final MaterialThemeBase currentTheme;
  final ExchangeViewModel exchangeViewModel;
  final AuthService authService;
  @override
  Widget contentWidget(BuildContext context) {
    return SwapConfirmationContent(
      paymentFlowResult: paymentFlowResult,
      exchangeViewModel: exchangeViewModel,
      authService: authService,
    );
  }
}

class SwapConfirmationContent extends StatefulWidget {
  const SwapConfirmationContent({
    Key? key,
    required this.paymentFlowResult,
    required this.exchangeViewModel,
    required this.authService,
  }) : super(key: key);

  final PaymentFlowResult paymentFlowResult;
  final ExchangeViewModel exchangeViewModel;
  final AuthService authService;

  @override
  SwapConfirmationContentState createState() => SwapConfirmationContentState();
}

class SwapConfirmationContentState extends State<SwapConfirmationContent> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final _receiveAmountDebounce = Debounce(Duration(milliseconds: 500));
  final FocusNode _amountFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  ReactionDisposer? _receiveAmountReaction;
  ReactionDisposer? _receiveAddressReaction;
  ReactionDisposer? _tradeStateReaction;
  ReactionDisposer? _bestRateReaction;
  bool _showingFailureDialog = false;

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();

    _receiveAmountReaction?.call();
    _receiveAddressReaction?.call();
    _tradeStateReaction?.call();
    _bestRateReaction?.call();

    _showingFailureDialog = false;

    widget.exchangeViewModel.bestRateSync.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _setUpReactions(
        context,
        widget.exchangeViewModel,
        widget.paymentFlowResult,
      ),
    );

    return Form(
      key: _formKey,
      child: Observer(
        builder: (_) {
          final detectedCurrencyName =
              walletTypeToCryptoCurrency(widget.paymentFlowResult.walletType!);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CakeImageWidget(
                      imageUrl: widget.exchangeViewModel.depositCurrency.iconPath!,
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_forward, size: 24),
                    const SizedBox(width: 12),
                    CakeImageWidget(
                      imageUrl: walletTypeToCryptoCurrency(widget.paymentFlowResult.walletType!)
                          .iconPath!,
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BaseTextFormField(
                  alignLabelWithHint: true,
                  controller: _amountController,
                  hintText: 'Amount (${detectedCurrencyName})',
                ),
                const SizedBox(height: 8),
                //TODO: Not linked yet
                BaseTextFormField(
                  alignLabelWithHint: true,
                  hintText: 'Amount (USD)',
                ),
                const SizedBox(height: 8),
                BaseTextFormField(
                  alignLabelWithHint: true,
                  hintText: 'Destination Address',
                  controller: _addressController,
                ),
                const SizedBox(height: 8),
                BaseTextFormField(
                  alignLabelWithHint: true,
                  hintText: 'Transaction Note',
                  controller: _noteController,
                ),
                const SizedBox(height: 16),
                SwapConfirmationFooter(
                  exchangeViewModel: widget.exchangeViewModel,
                  formKey: _formKey,
                  authService: widget.authService,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setUpReactions(
    BuildContext context,
    ExchangeViewModel exchangeViewModel,
    PaymentFlowResult paymentFlowResult,
  ) {
    _receiveAmountReaction = reaction((_) => exchangeViewModel.receiveAmount, (String amount) {
      if (_amountController.text != amount) {
        _amountController.text = amount;
      }
    });

    _receiveAddressReaction = reaction((_) => exchangeViewModel.receiveAddress, (String address) {
      if (_addressController.text != address) {
        _addressController.text = address;
      }
    });

    _tradeStateReaction = reaction((_) => exchangeViewModel.tradeState, (ExchangeTradeState state) {
      if (state is TradeIsCreatedFailure && !_showingFailureDialog) {
        _showingFailureDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                  key: const ValueKey('swap_confirmation_trade_creation_failure_dialog_key'),
                  buttonKey:
                      const ValueKey('swap_confirmation_trade_creation_failure_dialog_button_key'),
                  alertTitle: S.of(context).provider_error(state.title),
                  alertContent: state.error,
                  buttonText: S.of(context).ok,
                  buttonAction: () {
                    _showingFailureDialog = false;
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            );
          }
        });
      }

      if (state is TradeIsCreatedSuccessfully) {
        exchangeViewModel.reset();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(state.trade);
        }
      }
    });

    _bestRateReaction = reaction((_) => exchangeViewModel.bestRate, (double rate) {
      if (exchangeViewModel.isFixedRateMode) {
        exchangeViewModel.changeReceiveAmount(amount: _amountController.text);
      }
    });

    _addressController
        .addListener(() => exchangeViewModel.receiveAddress = _addressController.text);

    _amountController.addListener(() {
      if (_amountController.text != exchangeViewModel.receiveAmount) {
        _receiveAmountDebounce.run(() {
          exchangeViewModel.calculateBestRate();
          exchangeViewModel.changeReceiveAmount(amount: _amountController.text);
          exchangeViewModel.isReceiveAmountEntered = true;
        });
      }
    });

    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        exchangeViewModel.enableFixedRateMode();
      }
    });

    exchangeViewModel.receiveCurrency = walletTypeToCryptoCurrency(paymentFlowResult.walletType!);
    exchangeViewModel.receiveAddress = paymentFlowResult.addressDetectionResult?.address ?? '';
    if (exchangeViewModel.receiveAmount.isEmpty) {
      exchangeViewModel.receiveAmount = paymentFlowResult.addressDetectionResult?.amount ?? '0';
    }
    _addressController.text = exchangeViewModel.receiveAddress;
    _amountController.text = exchangeViewModel.receiveAmount;
    exchangeViewModel.isReceiveAmountEntered = true;
    exchangeViewModel.isFixedRateMode = true;
  }
}

class SwapConfirmationFooter extends StatelessWidget {
  const SwapConfirmationFooter({
    super.key,
    required this.exchangeViewModel,
    required this.formKey,
    required this.authService,
  });

  final ExchangeViewModel exchangeViewModel;
  final AuthService authService;
  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final isLoading = exchangeViewModel.tradeState is TradeIsCreating ||
            exchangeViewModel.limitsState is LimitsIsLoading;
        final isDisabled = exchangeViewModel.selectedProviders.isEmpty ||
            exchangeViewModel.receiveAmount.isEmpty ||
            exchangeViewModel.receiveAddress.isEmpty;

        return Container(
          height: 150,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                text: S.current.cancel,
                onPressed: isLoading
                    ? null
                    : () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(null);
                        }
                      },
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(height: 12),
              LoadingPrimaryButton(
                text: S.current.continue_text,
                onPressed: exchangeViewModel.isAvailableInSelected
                    ? () {
                        FocusScope.of(context).unfocus();

                        if (formKey.currentState != null && formKey.currentState!.validate()) {
                          final check = exchangeViewModel.shouldDisplayTOTP();
                          authService.authenticateAction(
                            context,
                            conditionToDetermineIfToUse2FA: check,
                            onAuthSuccess: (value) {
                              if (value) {
                                exchangeViewModel.createTrade();
                              }
                            },
                          );
                        }
                      }
                    : () => PresentProviderPicker(exchangeViewModel: exchangeViewModel)
                        .presentProviderPicker(context),
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                isDisabled: isDisabled,
                isLoading: isLoading,
              ),
            ],
          ),
        );
      },
    );
  }
}
