import 'dart:async';

import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/src/screens/receive/widgets/currency_input_field.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/payment_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/wallet_switcher_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/swap_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';

import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/di.dart';

class SendCard extends StatefulWidget {
  SendCard({
    Key? key,
    required this.output,
    required this.sendViewModel,
    required this.paymentViewModel,
    required this.walletSwitcherViewModel,
    required this.currentTheme,
    this.initialPaymentRequest,
    this.cryptoAmountFocus,
    this.fiatAmountFocus,
  }) : super(key: key);

  final Output output;
  final SendViewModel sendViewModel;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final PaymentRequest? initialPaymentRequest;
  final FocusNode? cryptoAmountFocus;
  final FocusNode? fiatAmountFocus;
  final MaterialThemeBase currentTheme;

  @override
  SendCardState createState() => SendCardState(
        output: output,
        sendViewModel: sendViewModel,
        paymentViewModel: paymentViewModel,
        walletSwitcherViewModel: walletSwitcherViewModel,
        initialPaymentRequest: initialPaymentRequest,
        currentTheme: currentTheme,
        // cryptoAmountFocus: cryptoAmountFocus ?? FocusNode(),
        // fiatAmountFocus: fiatAmountFocus ?? FocusNode(),
        // cryptoAmountFocus: FocusNode(),
        // fiatAmountFocus: FocusNode(),
      );
}

class SendCardState extends State<SendCard> with AutomaticKeepAliveClientMixin<SendCard> {
  SendCardState({
    required this.output,
    required this.sendViewModel,
    required this.paymentViewModel,
    required this.walletSwitcherViewModel,
    this.initialPaymentRequest,
    required this.currentTheme,
  })  : addressController = TextEditingController(),
        cryptoAmountController = TextEditingController(),
        fiatAmountController = TextEditingController(),
        noteController = TextEditingController(),
        extractedAddressController = TextEditingController(),
        addressFocusNode = FocusNode();

  static const prefixIconWidth = 34.0;
  static const prefixIconHeight = 34.0;

  final MaterialThemeBase currentTheme;
  final Output output;
  final SendViewModel sendViewModel;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final PaymentRequest? initialPaymentRequest;

  final TextEditingController addressController;
  final TextEditingController cryptoAmountController;
  final TextEditingController fiatAmountController;
  final TextEditingController noteController;
  final TextEditingController extractedAddressController;
  final FocusNode addressFocusNode;

  bool _effectsInstalled = false;
  BuildContext? loadingBottomSheetContext;
  bool _justHandledPasteButton = false;
  String _lastHandledAddress = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      sendViewModel.updateSendingBalance();
    });

    /// if the current wallet doesn't match the one in the qr code
    if (initialPaymentRequest != null &&
        sendViewModel.walletCurrencyName != initialPaymentRequest!.scheme.toLowerCase()) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          if (mounted) {
            final prefix =
                initialPaymentRequest!.scheme.isNotEmpty ? "${initialPaymentRequest!.scheme}:" : "";
            final amount = initialPaymentRequest!.amount.isNotEmpty
                ? "?amount=${initialPaymentRequest!.amount}"
                : "";
            final uri = prefix + initialPaymentRequest!.address + amount;
            _handlePaymentFlow(uri, initialPaymentRequest!);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    cryptoAmountController.dispose();
    fiatAmountController.dispose();
    noteController.dispose();
    extractedAddressController.dispose();
    addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentFlow(String uri, PaymentRequest paymentRequest) async {
    try {
      final result = await paymentViewModel.processAddress(uri);

      if (paymentRequest.contractAddress != null) {
        await sendViewModel.fetchTokenForContractAddress(paymentRequest.contractAddress!);
      }

      switch (result.type) {
        case PaymentFlowType.singleWallet:
        case PaymentFlowType.multipleWallets:
        case PaymentFlowType.noWallets:
          await _showPaymentConfirmation(
            paymentViewModel,
            walletSwitcherViewModel,
            paymentRequest,
            result,
          );
          break;
        case PaymentFlowType.currentWalletCompatible:
        case PaymentFlowType.error:
        case PaymentFlowType.incompatible:
          _applyPaymentRequest(paymentRequest);
          break;
      }
    } catch (e) {
      printV('Payment flow error: $e');
      _applyPaymentRequest(paymentRequest);
    }
  }

  Future<void> _showPaymentConfirmation(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
    PaymentFlowResult result,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return PaymentConfirmationBottomSheet(
          paymentFlowResult: result,
          paymentViewModel: paymentViewModel,
          walletSwitcherViewModel: walletSwitcherViewModel,
          paymentRequest: paymentRequest,
          onSelectWallet: () => _handleSelectWallet(
            paymentViewModel,
            walletSwitcherViewModel,
            paymentRequest,
          ),
          onChangeWallet: () => _handleChangeWallet(
            paymentViewModel,
            walletSwitcherViewModel,
            paymentRequest,
            result,
          ),
          onSwap: () => _handleSwapFlow(paymentViewModel, result),
        );
      },
    );
  }

  Future<void> _handleSelectWallet(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
  ) async {
    Navigator.of(context).pop();

    await showModalBottomSheet<WalletInfo>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return WalletSwitcherBottomSheet(
          viewModel: walletSwitcherViewModel,
          filterWalletType: paymentViewModel.detectedWalletType,
        );
      },
    );

    final success = await walletSwitcherViewModel.switchToSelectedWallet();

    if (success) {
      _applyPaymentRequest(paymentRequest);
    }
  }

  Future<void> _handleChangeWallet(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
    PaymentFlowResult result,
  ) async {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (result.wallet != null) {
      walletSwitcherViewModel.selectWallet(result.wallet!);
      final success = await walletSwitcherViewModel.switchToSelectedWallet();
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (BuildContext context) {
                loadingBottomSheetContext = context;
                return LoadingBottomSheet(
                  titleText: S.of(context).loading_your_wallet,
                );
              },
            );
          }
        });
        await Future.delayed(const Duration(seconds: 2));
        if (loadingBottomSheetContext != null && loadingBottomSheetContext!.mounted) {
          Navigator.of(loadingBottomSheetContext!).pop();
        }
        _applyPaymentRequest(paymentRequest);
      }
    }
  }

  /// Apply payment request to current form
  void _applyPaymentRequest(PaymentRequest paymentRequest) {
    if (sendViewModel.usePayjoin) {
      sendViewModel.payjoinUri = paymentRequest.pjUri;
    }
    addressController.text = paymentRequest.address;
    if (paymentRequest.amount.isNotEmpty) {
      cryptoAmountController.text = paymentRequest.amount;
    }
    noteController.text = paymentRequest.note;
  }

  Future<void> _handleSwapFlow(PaymentViewModel paymentViewModel, PaymentFlowResult result) async {
    Navigator.of(context).pop();
    final bottomSheet = getIt.get<SwapConfirmationBottomSheet>(param1: result);
    await showModalBottomSheet<Trade?>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) => bottomSheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _setEffects(context);

    // return Stack(
    //   children: [
    // return KeyboardActions(
    //   config: KeyboardActionsConfig(
    //     keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
    //     keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
    //     nextFocus: false,
    //     actions: [
    //       KeyboardActionsItem(
    //         focusNode: cryptoAmountFocus,
    //         toolbarButtons: [(_) => KeyboardDoneButton()],
    //       ),
    //       KeyboardActionsItem(
    //         focusNode: fiatAmountFocus,
    //         toolbarButtons: [(_) => KeyboardDoneButton()],
    //       )
    //     ],
    //   ),
    //   // child: Container(
    //   //   height: 0,
    //   //   color: Colors.transparent,
    //   // ),      child:
    //   child: SizedBox(
    //     height: 100,
    //     width: 100,
    //     child: Text('Send Card'),
    //   ),
    // );
    return Container(
      decoration: responsiveLayoutUtil.shouldRenderMobileUI
          ? BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              color: Theme.of(context).colorScheme.surfaceContainer,
            )
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          responsiveLayoutUtil.shouldRenderMobileUI ? 110 : 55,
          24,
          responsiveLayoutUtil.shouldRenderMobileUI ? 32 : 0,
        ),
        child: Observer(
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Observer(builder: (_) {
                final validator = output.isParsedAddress
                    ? sendViewModel.textValidator
                    : sendViewModel.addressValidator;

                return AddressTextField(
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hasUnderlineBorder: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  addressKey: ValueKey('send_page_address_textfield_key'),
                  focusNode: addressFocusNode,
                  controller: addressController,
                  onURIScanned: (uri) async {
                    if (OpenCryptoPayService.isOpenCryptoPayQR(uri.toString())) {
                      sendViewModel.createOpenCryptoPayTransaction(uri.toString());
                    } else {
                      // Process the payment through the new flow
                      await _handlePaymentFlow(
                        uri.toString(),
                        PaymentRequest.fromUri(uri),
                      );
                    }
                  },
                  options: [
                    AddressTextFieldOption.paste,
                    AddressTextFieldOption.qrCode,
                    AddressTextFieldOption.addressBook
                  ],
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                  hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  onPushPasteButton: (context) async {
                    _justHandledPasteButton = true;
                    try {
                      output.resetParsedAddress();
                      await output.fetchParsedAddress(context);

                      final address =
                          output.isParsedAddress ? output.extractedAddress : output.address;

                      await _handlePaymentFlow(
                        address,
                        PaymentRequest(
                          address,
                          cryptoAmountController.text,
                          noteController.text,
                          "",
                          null,
                        ),
                      );
                    } finally {
                      _justHandledPasteButton = false;
                    }
                  },
                  onPushAddressBookButton: (context) async {
                    output.resetParsedAddress();
                  },
                  onSelectedContact: (contact) {
                    output.loadContact(contact);
                  },
                  validator: validator,
                  selectedCurrency: sendViewModel.selectedCryptoCurrency,
                );
              }),
              if (output.isParsedAddress)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: BaseTextFormField(
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    controller: extractedAddressController,
                    readOnly: true,
                    enableInteractiveSelection: false,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    validator: sendViewModel.addressValidator,
                  ),
                ),
              CurrencyAmountTextField(
                borderWidth: 0.0,
                hasUnderlineBorder: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                currencyPickerButtonKey: ValueKey('send_page_currency_picker_button_key'),
                amountTextfieldKey: ValueKey('send_page_amount_textfield_key'),
                sendAllButtonKey: ValueKey('send_page_send_all_button_key'),
                currencyAmountTextFieldWidgetKey:
                    ValueKey('send_page_crypto_currency_amount_textfield_widget_key'),
                selectedCurrency: sendViewModel.selectedCryptoCurrency.title,
                selectedCurrencyDecimals: sendViewModel.selectedCryptoCurrency.decimals,
                amountFocusNode: widget.cryptoAmountFocus,
                amountController: cryptoAmountController,
                isAmountEditable: true,
                onTapPicker: () => _presentPicker(context),
                isPickerEnable: sendViewModel.hasMultipleTokens,
                tag: sendViewModel.selectedCryptoCurrency.tag,
                allAmountButton:
                    !sendViewModel.isBatchSending && sendViewModel.shouldDisplaySendALL,
                currencyValueValidator: output.sendAll
                    ? sendViewModel.allAmountValidator
                    : sendViewModel.amountValidator(output),
                allAmountCallback: () async =>
                    output.setSendAll(await sendViewModel.sendingBalance),
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              Observer(
                builder: (_) {
                  // force rebuild on mobx
                  final _ = sendViewModel.coinTypeToSpendFrom;
                  return Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            S.of(context).available_balance + ':',
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        FutureBuilder<String>(
                          future: sendViewModel.sendingBalance,
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ??
                                  sendViewModel.balance, // default to balance while loading
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            );
                          },
                        )
                      ],
                    ),
                  );
                },
              ),
              if (!sendViewModel.isFiatDisabled)
                CurrencyAmountTextField(
                  borderWidth: 0.0,
                  hasUnderlineBorder: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  amountTextfieldKey: ValueKey('send_page_fiat_amount_textfield_key'),
                  currencyAmountTextFieldWidgetKey:
                      ValueKey('send_page_fiat_currency_amount_textfield_widget_key'),
                  selectedCurrency: sendViewModel.fiat.title,
                  selectedCurrencyDecimals: sendViewModel.fiat.decimals,
                  amountFocusNode: widget.fiatAmountFocus,
                  amountController: fiatAmountController,
                  hintText: '0.00',
                  isAmountEditable: true,
                  allAmountButton: false,
                ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: BaseTextFormField(
                  hasUnderlineBorder: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  key: ValueKey('send_page_note_textfield_key'),
                  controller: noteController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  hintText: S.of(context).note_optional,
                  placeholderTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (sendViewModel.feesViewModel.hasFees)
                Observer(
                  builder: (_) => GestureDetector(
                    key: ValueKey('send_page_select_fee_priority_button_key'),
                    onTap: sendViewModel.feesViewModel.hasFeesPriority
                        ? () => pickTransactionPriority(context, output)
                        : () {},
                    child: Container(
                      padding: EdgeInsets.only(top: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            S.of(context).send_estimated_fee,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Container(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      output.estimatedFee.toString() +
                                          ' ' +
                                          sendViewModel.currency.toString(),
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: sendViewModel.isFiatDisabled
                                          ? const SizedBox(height: 14)
                                          : Text(
                                              output.estimatedFeeFiatAmount +
                                                  ' ' +
                                                  sendViewModel.fiat.title,
                                              style:
                                                  Theme.of(context).textTheme.bodySmall!.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                            ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 2, left: 5),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              if (sendViewModel.hasCoinControl)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    key: ValueKey('send_page_unspent_coin_button_key'),
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        Routes.unspentCoinsList,
                        arguments: widget.sendViewModel.coinTypeToSpendFrom,
                      );
                      if (mounted) {
                        // we just got back from the unspent coins list screen, so we need to recompute the sending balance:
                        sendViewModel.updateSendingBalance();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            S.of(context).coin_control,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (sendViewModel.currency == CryptoCurrency.ltc && sendViewModel.isMwebEnabled)
                Observer(
                  builder: (_) => Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: GestureDetector(
                      key: ValueKey('send_page_unspent_coin_button_key'),
                      onTap: () {
                        bool value =
                            widget.sendViewModel.coinTypeToSpendFrom == UnspentCoinType.any;
                        sendViewModel.setAllowMwebCoins(!value);
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
                                  widget.sendViewModel.coinTypeToSpendFrom == UnspentCoinType.any,
                              onChanged: (bool? value) {
                                sendViewModel.setAllowMwebCoins(value ?? false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    if (output.address.isNotEmpty) {
      addressController.text = output.address;
    }
    if (output.cryptoAmount.isNotEmpty) {
      cryptoAmountController.text = output.cryptoAmount;
    }
    fiatAmountController.text = output.fiatAmount;
    noteController.text = output.note;
    extractedAddressController.text = output.extractedAddress;

    cryptoAmountController.addListener(() {
      final amount = cryptoAmountController.text;

      if (output.sendAll && amount != S.current.all) {
        output.sendAll = false;
      }

      if (amount != output.cryptoAmount) {
        output.setCryptoAmount(amount);
      }
    });

    fiatAmountController.addListener(() {
      final amount = fiatAmountController.text;

      if (amount != output.fiatAmount) {
        output.sendAll = false;
        output.setFiatAmount(amount);
      }
    });

    noteController.addListener(() {
      final note = noteController.text;

      if (note != output.note) {
        output.note = note;
      }
    });

    reaction((_) => output.sendAll, (bool all) {
      if (all) cryptoAmountController.text = S.current.all;
    });

    reaction((_) => sendViewModel.selectedCryptoCurrency, (Currency currency) async {
      if (output.sendAll) {
        output.setSendAll(await sendViewModel.sendingBalance);
      }

      output.setCryptoAmount(cryptoAmountController.text);
    });

    reaction((_) => output.fiatAmount, (String amount) {
      if (amount != fiatAmountController.text) {
        fiatAmountController.text = amount;
      }
    });

    reaction((_) => output.cryptoAmount, (String amount) {
      if (output.sendAll && amount != S.current.all) {
        output.sendAll = false;
      }

      if (amount != cryptoAmountController.text) {
        cryptoAmountController.text = amount;
      }
    });

    reaction((_) => output.address, (String address) {
      if (address != addressController.text) {
        addressController.text = address;
      }
    });

    addressController.addListener(() {
      final address = addressController.text;

      if (output.address != address) {
        output.resetParsedAddress();
        output.address = address;

        if (sendViewModel.isLightningInvoice(address)) {
          sendViewModel.createTransaction();
        }
      }
    });

    reaction((_) => output.note, (String note) {
      if (note != noteController.text) {
        noteController.text = note;
      }
    });

    addressFocusNode.addListener(() async {
      if (!addressFocusNode.hasFocus && addressController.text.isNotEmpty) {
        final current = addressController.text.trim();
        if (current.isEmpty) return;
        if (_justHandledPasteButton || _lastHandledAddress == current) return;

        await output.fetchParsedAddress(context);

        // If it's a URI with params, go through URI flow
        if (current.contains('=')) {
          try {
            final uri = Uri.parse(current);
            _lastHandledAddress = current;
            await _handlePaymentFlow(
              uri.toString(),
              PaymentRequest.fromUri(uri),
            );
            return;
          } catch (_) {
            // fall through to plain address
          }
        }

        final parsedAddress = output.isParsedAddress ? output.extractedAddress : output.address;

        _lastHandledAddress = current;
        await _handlePaymentFlow(
          parsedAddress,
          PaymentRequest(
            parsedAddress,
            cryptoAmountController.text,
            noteController.text,
            "",
            null,
          ),
        );
      }
    });

    reaction((_) => output.extractedAddress, (String extractedAddress) {
      extractedAddressController.text = extractedAddress;
    });

    if (initialPaymentRequest != null &&
        sendViewModel.walletCurrencyName == initialPaymentRequest!.scheme.toLowerCase()) {
      addressController.text = initialPaymentRequest!.address;
      cryptoAmountController.text = initialPaymentRequest!.amount;
      noteController.text = initialPaymentRequest!.note;
    }

    reaction((_) => sendViewModel.isReadyForSend, (bool isReadyForSend) {
      if (isReadyForSend) {
        sendViewModel.updateSendingBalance();
      }
    });

    _effectsInstalled = true;
  }

  Future<void> pickTransactionPriority(BuildContext context, Output output) async {
    final items = priorityForWalletType(sendViewModel.walletType);
    final selectedItem = items.indexOf(sendViewModel.feesViewModel.transactionPriority);
    final customItemIndex = sendViewModel.feesViewModel.getCustomPriorityIndex(items);
    final isBitcoinWallet = sendViewModel.walletType == WalletType.bitcoin;
    final maxCustomFeeRate = sendViewModel.feesViewModel.maxCustomFeeRate?.toDouble();
    double? customFeeRate =
        isBitcoinWallet ? sendViewModel.feesViewModel.customBitcoinFeeRate.toDouble() : null;

    FocusManager.instance.primaryFocus?.unfocus();

    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        int selectedIdx = selectedItem;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Picker(
              items: items,
              displayItem: (TransactionPriority priority) =>
                  sendViewModel.feesViewModel.displayFeeRate(priority, customFeeRate?.round()),
              selectedAtIndex: selectedIdx,
              customItemIndex: customItemIndex,
              maxValue: maxCustomFeeRate,
              title: S.of(context).please_select,
              headerEnabled: !isBitcoinWallet,
              closeOnItemSelected: !isBitcoinWallet,
              mainAxisAlignment: MainAxisAlignment.center,
              sliderValue: customFeeRate,
              onSliderChanged: (double newValue) => setState(() => customFeeRate = newValue),
              onItemSelected: (TransactionPriority priority) async {
                sendViewModel.feesViewModel.setTransactionPriority(priority);
                setState(() => selectedIdx = items.indexOf(priority));
                await output.calculateEstimatedFee();
              },
            );
          },
        );
      },
    );
    if (isBitcoinWallet) sendViewModel.feesViewModel.customBitcoinFeeRate = customFeeRate!.round();
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (_) => CurrencyPicker(
        key: ValueKey('send_page_currency_picker_dialog_button_key'),
        selectedAtIndex: sendViewModel.currencies.indexOf(sendViewModel.selectedCryptoCurrency),
        items: sendViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency cur) =>
            sendViewModel.selectedCryptoCurrency = (cur as CryptoCurrency),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
