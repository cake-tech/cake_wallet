import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/exchange/limits_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/present_provider_picker.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/swap_details_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cw_core/crypto_amount_format.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.sessionId,
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
  final String? sessionId;
  @override
  Widget contentWidget(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SwapConfirmationContent(
        paymentFlowResult: paymentFlowResult,
        exchangeViewModel: exchangeViewModel,
        authService: authService,
      ),
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
  late TextEditingController _amountController;
  late TextEditingController _amountFiatController;
  late TextEditingController _addressController;

  final _receiveAmountDebounce = Debounce(Duration(milliseconds: 500));
  final _receiveAmountFiatDebounce = Debounce(Duration(milliseconds: 500));
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _amountFiatFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  ReactionDisposer? _receiveAmountReaction;
  ReactionDisposer? _receiveAddressReaction;
  ReactionDisposer? _tradeStateReaction;
  ReactionDisposer? _bestRateReaction;
  ReactionDisposer? _receiveAmountFiatReaction;

  bool _showingFailureDialog = false;
  bool _showingSwapDetailsDialog = false;
  bool _isUserTypingFiat = false;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.paymentFlowResult.addressDetectionResult?.address ?? '');
    _amountController = TextEditingController(
        text: widget.paymentFlowResult.addressDetectionResult?.amount?.isNotEmpty ?? false
            ? widget.paymentFlowResult.addressDetectionResult?.amount
            : '0.00');
    _amountFiatController =
        TextEditingController(text: widget.exchangeViewModel.receiveAmountFiatFormatted);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _setUpReactions(
        context,
        widget.exchangeViewModel,
        widget.paymentFlowResult,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFiatController.dispose();
    _addressController.dispose();
    _amountFocus.dispose();
    _amountFiatFocus.dispose();
    _addressFocus.dispose();
    _receiveAmountReaction?.call();
    _receiveAddressReaction?.call();
    _tradeStateReaction?.call();
    _bestRateReaction?.call();
    _receiveAmountFiatReaction?.call();
    _showingFailureDialog = false;
    _showingSwapDetailsDialog = false;
    widget.exchangeViewModel.bestRateSync.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectedCurrencyName = walletTypeToCryptoCurrency(widget.paymentFlowResult.walletType!);

    return Form(
      key: _formKey,
      child: Padding(
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
                  imageUrl:
                      walletTypeToCryptoCurrency(widget.paymentFlowResult.walletType!).iconPath!,
                  width: 32,
                  height: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwapConfirmationTextfield(
              key: ValueKey('swap_confirmation_bottomsheet_amount_textfield_key'),
              hintText: 'Amount (${detectedCurrencyName})',
              focusNode: _amountFocus,
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]')),
              ],
              onChanged: (value) {
                final sanitized = value
                    .replaceAll(',', '.')
                    .withMaxDecimals(widget.exchangeViewModel.receiveCurrency.decimals);
                if (sanitized != _amountController.text) {
                  // Update text while preserving a sane cursor position to avoid auto-selection
                  _amountController.value = _amountController.value.copyWith(
                    text: sanitized,
                    selection: TextSelection.collapsed(offset: sanitized.length),
                    composing: TextRange.empty,
                  );
                }
              },
              validator: (value) {
                return AmountValidator(
                  isAutovalidate: true,
                  currency: widget.exchangeViewModel.receiveCurrency,
                  minValue: widget.exchangeViewModel.limits.min.toString(),
                  maxValue: widget.exchangeViewModel.limits.max.toString(),
                ).call(value);
              },
            ),
            Observer(
              builder: (_) {
                String? min = '0.0';
                String? max = '0.0';

                final limitsState = widget.exchangeViewModel.limitsState;
                if (limitsState is LimitsLoadedSuccessfully) {
                  min = limitsState.limits.min?.toString();
                  max = limitsState.limits.max?.toString();
                }

                if (limitsState is LimitsLoadedFailure) {
                  min = '0.0';
                  max = '0.0';
                }

                if (limitsState is LimitsIsLoading) {
                  min = '...';
                  max = '...';
                }
                if (min != null || max != null) {
                  return Container(
                    height: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        min != null
                            ? Text(
                                key: ValueKey('min_limit_text_key'),
                                S.of(context).min_value(min, detectedCurrencyName.toString()),
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 10,
                                      height: 1.2,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              )
                            : Offstage(),
                        min != null ? SizedBox(width: 10) : Offstage(),
                        max != null
                            ? Text(
                                key: ValueKey('max_limit_text_key'),
                                S.of(context).max_value(max, detectedCurrencyName.toString()),
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 10,
                                      height: 1.2,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              )
                            : Offstage(),
                      ],
                    ),
                  );
                }

                return SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            SwapConfirmationTextfield(
              key: ValueKey('swap_confirmation_bottomsheet_amount_fiat_textfield_key'),
              hintText: 'Amount (${widget.exchangeViewModel.fiat.title})',
              focusNode: _amountFiatFocus,
              controller: _amountFiatController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            SwapConfirmationTextfield(
              key: ValueKey('swap_confirmation_bottomsheet_address_textfield_key'),
              isAddress: true,
              walletType: cryptoCurrencyToWalletType(widget.exchangeViewModel.receiveCurrency),
              hintText: 'Destination Address',
              focusNode: _addressFocus,
              controller: _addressController,
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Tap field to edit values',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SizedBox(height: 32),
            SwapConfirmationFooter(
              exchangeViewModel: widget.exchangeViewModel,
              formKey: _formKey,
              authService: widget.authService,
            ),
          ],
        ),
      ),
    );
  }

  void _setUpReactions(
    BuildContext context,
    ExchangeViewModel exchangeViewModel,
    PaymentFlowResult paymentFlowResult,
  ) async {
    _receiveAmountReaction = reaction((_) => exchangeViewModel.receiveAmount, (String amount) {
      if (_amountController.text != amount) {
        _amountController.text = amount;
      }
    });

    _receiveAmountFiatReaction =
        reaction((_) => exchangeViewModel.receiveAmountFiatFormatted, (String amount) {
      if (!_isUserTypingFiat && _amountFiatController.text != amount) {
        _amountFiatController.text = amount;
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
        if (Navigator.of(context).canPop() && !_showingSwapDetailsDialog) {
          _showingSwapDetailsDialog = true;
          Navigator.of(context).pop();
          showModalBottomSheet<void>(
            context: context,
            isDismissible: true,
            isScrollControlled: true,
            builder: (BuildContext context) {
              _showingSwapDetailsDialog = false;
              return getIt.get<SwapDetailsBottomSheet>();
            },
          );
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
          exchangeViewModel.loadLimits();
          exchangeViewModel.changeReceiveAmount(amount: _amountController.text);
          exchangeViewModel.isReceiveAmountEntered = true;
        });
      }
    });

    _amountFiatController.addListener(() {
      if (_amountFiatController.text != exchangeViewModel.receiveAmountFiatFormatted) {
        _isUserTypingFiat = true;
        _receiveAmountFiatDebounce.run(() {
          exchangeViewModel.loadLimits();
          exchangeViewModel.setReceiveAmountFromFiat(fiatAmount: _amountFiatController.text);
          // Reset the flag after the debounced operation completes
          Future.delayed(Duration(milliseconds: 100), () {
            _isUserTypingFiat = false;
          });
        });
      }
    });

    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        exchangeViewModel.enableFixedRateMode();
      }
    });

    _amountFiatFocus.addListener(() {
      if (_amountFiatFocus.hasFocus) {
        _isUserTypingFiat = true;
      } else {
        // Reset the flag when user stops focusing on the field
        Future.delayed(Duration(milliseconds: 200), () {
          _isUserTypingFiat = false;
        });
      }
    });

    exchangeViewModel.receiveCurrency = walletTypeToCryptoCurrency(paymentFlowResult.walletType!);
    await exchangeViewModel.fetchFiatPrice(exchangeViewModel.receiveCurrency);

    exchangeViewModel.receiveAddress = _addressController.text;
    exchangeViewModel.depositAddress = exchangeViewModel.wallet.walletAddresses.addressForExchange;
    exchangeViewModel.receiveAmount = _amountController.text;
    _amountFiatController.text = exchangeViewModel.receiveAmountFiatFormatted;
    exchangeViewModel.isReceiveAmountEntered = true;
    exchangeViewModel.isFixedRateMode = true;
  }
}

class SwapConfirmationTextfield extends StatelessWidget {
  const SwapConfirmationTextfield({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.hintText,
    this.walletType,
    this.isAddress = false,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final String hintText;
  final WalletType? walletType;
  final bool isAddress;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: focusNode.hasFocus
              ? BorderSide(color: Theme.of(context).colorScheme.primary)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hintText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (isAddress) SizedBox(height: 8),
          isAddress
              ? AddressFormatter.buildSegmentedAddress(
                  address: controller.text,
                  walletType: walletType,
                  evenTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                )
              : BaseTextFormField(
                  isDense: true,
                  hintText: hintText,
                  focusNode: focusNode,
                  hasUnderlineBorder: true,
                  borderWidth: 0.0,
                  controller: controller,
                  maxLines: maxLines,
                  validator: validator,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  inputFormatters: inputFormatters,
                ),
        ],
      ),
    );
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
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Observer(
        builder: (_) {
          final isLoading = exchangeViewModel.tradeState is TradeIsCreating ||
              exchangeViewModel.limitsState is LimitsIsLoading;
          final isDisabled = exchangeViewModel.selectedProviders.isEmpty ||
              exchangeViewModel.receiveAmount.isEmpty ||
              exchangeViewModel.receiveAddress.isEmpty;

          return Column(
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
          );
        },
      ),
    );
  }
}
