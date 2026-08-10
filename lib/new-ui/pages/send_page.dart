import "package:cake_wallet/core/address_resolver/parsed_address.dart";
import "package:cake_wallet/core/address_validator.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/contact_record.dart";
import "package:cake_wallet/entities/priority_for_wallet_type.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/coin_control_page.dart";
import "package:cake_wallet/new-ui/widgets/animated_dropdown.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_future_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/picker.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart";
import "package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/l2_action_wallet_selector.dart";
import "package:cake_wallet/new-ui/widgets/send_page/recipient_dot_row.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_memo_input.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_syncing_indicator.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/routes.dart" show Routes;
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/payment_confirmation_bottom_sheet.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/swap_confirmation_bottom_sheet.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/token_selection_bottom_sheet.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/wallet_switcher_bottom_sheet.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart";
import "package:cake_wallet/src/widgets/standard_checkbox.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/contact_list/contact_list_view_model.dart";
import "package:cake_wallet/view_model/payment/payment_view_model.dart";
import "package:cake_wallet/view_model/send/output.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cake_wallet/view_model/send/send_view_model_state.dart";
import "package:cake_wallet/view_model/wallet_switcher_view_model.dart";
import "package:cw_core/amount/amount_sanitizer.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/lnurl.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class SendPageHelpContent {
  const SendPageHelpContent({
    required this.title,
    required this.imagePath,
    required this.description,
    this.disclaimer,
  });

  final String imagePath;
  final String title;
  final String description;
  final String? disclaimer;
}

class SendPageModes {
  const SendPageModes({
    required this.title,
    required this.showAddressField,
    this.description,
    this.confirmSheetIconPath,
    this.helpContent,
    this.popOnConfirmation = true,
  });

  final bool showAddressField;
  final String title;
  final String? description;
  final String? confirmSheetIconPath;
  final SendPageHelpContent? helpContent;
  final bool popOnConfirmation;

  static final SendPageModes normal = SendPageModes(title: S.current.send, showAddressField: true);

  static final SendPageModes lightningDeposit = SendPageModes(
    title: S.current.bitcoin_lightning_deposit,
    description: S.current.to_lightning,
    showAddressField: false,
    helpContent: SendPageHelpContent(
      title: S.current.bitcoin_lightning_deposit,
      imagePath: "assets/new-ui/lightning_deposit_help.svg",
      description: S.current.lightning_deposit_desc,
      disclaimer: S.current.lightning_deposit_disclaimer,
    ),
    popOnConfirmation: false,
  );

  static final SendPageModes lightningWithdrawal = SendPageModes(
    title: S.current.bitcoin_lightning_withdraw,
    description: S.current.to_on_chain,
    showAddressField: false,
    helpContent: SendPageHelpContent(
      title: S.current.bitcoin_lightning_withdraw,
      imagePath: "assets/new-ui/lightning_withdraw_help.svg",
      description: S.current.lightning_withdraw_desc,
      disclaimer: S.current.lightning_withdraw_disclaimer,
    ),
    popOnConfirmation: false,
  );

  static final SendPageModes mwebDeposit = SendPageModes(
    title: "${S.current.mask} Litecoin",
    showAddressField: false,
    confirmSheetIconPath: "assets/new-ui/mask.svg",
    helpContent: SendPageHelpContent(
      title: S.current.about_litecoin_privacy,
      imagePath: "assets/new-ui/mweb_help.svg",
      description: "${S.current.mweb_help_desc_1}\n\n${S.current.mweb_help_desc_2}",
      disclaimer: S.current.mweb_help_disclaimer,
    ),
    popOnConfirmation: false,
  );

  static final SendPageModes mwebWithdrawal = SendPageModes(
    title: "${S.current.unmask} Litecoin",
    showAddressField: false,
    confirmSheetIconPath: "assets/new-ui/unmask.svg",
    helpContent: SendPageHelpContent(
      title: S.current.about_litecoin_privacy,
      imagePath: "assets/new-ui/mweb_help.svg",
      description: "${S.current.mweb_help_desc_1}\n\n${S.current.mweb_help_desc_2}",
      disclaimer: S.current.mweb_help_disclaimer,
    ),
    popOnConfirmation: false,
  );

  static final all = [normal, lightningDeposit, lightningWithdrawal, mwebDeposit, mwebWithdrawal];
}

class SendPageParams {
  SendPageParams({
    this.initialPaymentRequest,
    SendPageModes? mode,
    this.unspentCoinType = UnspentCoinType.any,
    this.initialCurrency,
  }) : mode = mode ?? SendPageModes.normal;

  final PaymentRequest? initialPaymentRequest;
  final SendPageModes mode;
  final CryptoCurrency? initialCurrency;
  final UnspentCoinType unspentCoinType;
}

class NewSendPage extends StatefulWidget {
  NewSendPage({
    required this.sendViewModel,
    required this.paymentViewModel,
    required this.walletSwitcherViewModel,
    required this.contactListViewModel,
    required this.authService,
    required SendPageParams params,
    super.key,
  })  : initialPaymentRequest = params.initialPaymentRequest,
        mode = params.mode {
    if (params.initialCurrency != null) {
      sendViewModel.selectedCryptoCurrency = params.initialCurrency!;
    }
  }

  final SendViewModel sendViewModel;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final ContactListViewModel contactListViewModel;
  final AuthService authService;
  final PaymentRequest? initialPaymentRequest;
  final SendPageModes mode;

  @override
  State<NewSendPage> createState() => _NewSendPageState();
}

class _NewSendPageState extends State<NewSendPage> {
  int _selectedOutput = 0;

  final _amountControllers = <TextEditingController>[];
  final _addressControllers = <TextEditingController>[];
  final _memoControllers = <TextEditingController>[];
  final _formKey = GlobalKey<FormState>();
  final _addressFocusNode = FocusNode();
  BuildContext? loadingBottomSheetContext;
  BuildContext? dialogContext;
  ContactRecord? newContactAddress;

  bool _justHandledPasteButton = false;

  @override
  void initState() {
    super.initState();
    _addInputControllers();

    reaction((_) => widget.sendViewModel.outputs[_selectedOutput].sendAll, (all) {
      if (all) {
        widget.sendViewModel.outputs[_selectedOutput].isFiatEntry = false;
        _amountControllers[_selectedOutput].text = S.current.all;
      }
    });

    reaction((_) => widget.sendViewModel.outputs[_selectedOutput].address, (address) {
      if (_addressControllers[_selectedOutput].text != address) {
        _addressControllers[_selectedOutput].text = address;
      }
    });

    reaction((_) => widget.sendViewModel.outputs[_selectedOutput].memo, (memo) {
      if (memo != _memoControllers[_selectedOutput].text) {
        _memoControllers[_selectedOutput].text = memo;
      }
    });

    if (widget.initialPaymentRequest != null &&
        widget.sendViewModel.walletCurrencyName ==
            widget.initialPaymentRequest!.scheme.toLowerCase()) {
      _addressControllers[0].text = widget.initialPaymentRequest!.address;
      _amountControllers[0].text = widget.initialPaymentRequest!.amount;
      // _memoControllers[0].text = widget.initialPaymentRequest!.note;
      _applyNote(widget.initialPaymentRequest!.note, 0);

      final contractAddress = widget.initialPaymentRequest!.contractAddress;
      if (contractAddress != null && contractAddress.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.sendViewModel.fetchTokenForContractAddress(contractAddress);
          }
        });
      }
    }

    /// if the current wallet doesn't match the one in the qr code
    if (widget.initialPaymentRequest != null &&
        widget.sendViewModel.walletCurrencyName !=
            widget.initialPaymentRequest!.scheme.toLowerCase()) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          if (mounted) {
            final prefix = widget.initialPaymentRequest!.scheme.isNotEmpty
                ? "${widget.initialPaymentRequest!.scheme}:"
                : "";
            final amount = widget.initialPaymentRequest!.amount.isNotEmpty
                ? "?amount=${widget.initialPaymentRequest!.amount}"
                : "";
            final uri = prefix + widget.initialPaymentRequest!.address + amount;
            _handlePaymentFlow(uri, widget.initialPaymentRequest!);
          }
        },
      );
    }

    _addressFocusNode.addListener(() async {
      if (!_addressFocusNode.hasFocus && _addressControllers[_selectedOutput].text.isNotEmpty) {
        final output = widget.sendViewModel.outputs[_selectedOutput];
        await _resolveAddressForOutput(output);
      }
    });
  }

  Future<void> _resolveAddressForOutput(Output output) async {
    final result = await widget.sendViewModel.resolveAddressForOutput(output);
    if (result == null || !mounted) {
      return;
    }

    final confirmed = await showParsedAddressConfirmationAlert(context, result);

    if (confirmed) {
      output.applyAddressLookupResult(result);
    } else {
      output.resetParsedAddress();
      return;
    }

    final outputIndex = widget.sendViewModel.outputs.indexOf(output);
    if (outputIndex >= 0 &&
        outputIndex < _addressControllers.length &&
        output.extractedAddress.isNotEmpty &&
        _addressControllers[outputIndex].text != output.extractedAddress) {
      _addressControllers[outputIndex].text = output.extractedAddress;
    }
  }

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) {
          final output = widget.sendViewModel.outputs[_selectedOutput];
          return SafeArea(
            bottom: false,
            child: KeyboardHideOverlay(
              unfocusOnTap: true,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Column(
                    spacing: 12,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ModalTopBar(
                        title: widget.mode.title,
                        subtitle: widget.mode.description,
                        leadingIcon: const Icon(Icons.close),
                        leadingSemanticLabel: S.of(context).close,
                        onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                        trailingWidget: Observer(
                          builder: (_) => Row(
                            spacing: 8,
                            children: [
                              if (widget.sendViewModel.outputs.length > 1)
                                ModernButton(
                                  size: 36,
                                  icon: CakeImageWidget(
                                    imageUrl: "assets/new-ui/remove_recipient.svg",
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.primary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  semanticLabel: S.of(context).remove,
                                  onPressed: () {
                                    final outputIndex = _selectedOutput;
                                    if (_selectedOutput != 0) {
                                      _setOutput(_selectedOutput - 1);
                                    } else {
                                      _setOutput(1);
                                    }
                                    _removeInputControllers(outputIndex);
                                    widget.sendViewModel.removeOutput(output);
                                    if (outputIndex == 0) {
                                      _setOutput(0);
                                    }
                                  },
                                ),
                              if (widget.mode == SendPageModes.normal &&
                                  widget.sendViewModel.hasMultiRecipient)
                                ModernButton(
                                  size: 36,
                                  icon: const Icon(Icons.add),
                                  semanticLabel: S.of(context).add_receiver,
                                  onPressed: () {
                                    _addInputControllers();
                                    widget.sendViewModel.addOutput();
                                    _setOutput(widget.sendViewModel.outputs.length - 1);
                                  },
                                ),
                              if (widget.mode.helpContent != null)
                                ModernButton(
                                  size: 36,
                                  icon: CakeImageWidget(
                                    imageUrl: "assets/new-ui/help.svg",
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(context).colorScheme.primary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  semanticLabel: S.of(context).help,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => Material(
                                          child: SendHelpPage(content: widget.mode.helpContent!),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Form(
                                key: _formKey,
                                child: DirectionalAnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Column(
                                    key: ValueKey(_selectedOutput),
                                    spacing: 24,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (widget.mode.showAddressField)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          spacing: 12,
                                          children: [
                                            // NewSendAddressInput merges this label onto its
                                            // own text-field node, so announcing the caption
                                            // as well would read it twice.
                                            ExcludeSemantics(
                                              child: Text(S.of(context).address_or_alias),
                                            ),
                                            NewSendAddressInput(
                                              displayName: output.displayName,
                                              validator: output.isParsedAddress
                                                  ? widget.sendViewModel.textValidator
                                                  : widget.sendViewModel.addressValidator,
                                              addressController:
                                                  _addressControllers[_selectedOutput],
                                              focusNode: _addressFocusNode,
                                              onURIScanned: (uri) async {
                                                output.resetParsedAddress();
                                                await _resolveAddressForOutput(output);

                                                // Process the payment through the new flow
                                                await _handlePaymentFlow(
                                                  uri.toString(),
                                                  PaymentRequest.fromString(uri.toString()),
                                                );
                                              },
                                              onEditingComplete: _addressFocusNode.unfocus,
                                              onPushAddressBookButton: (_) {
                                                output.resetParsedAddress();
                                              },
                                              onSelectedContact: (contact) {
                                                output.loadContact(contact);
                                              },
                                              onPushPasteButton: (context) async {
                                                if (_justHandledPasteButton) {
                                                  return;
                                                }
                                                _justHandledPasteButton = true;
                                                try {
                                                  output.resetParsedAddress();
                                                  await _resolveAddressForOutput(output);

                                                  final address = output.isParsedAddress
                                                      ? output.extractedAddress
                                                      : output.address;

                                                  await _handlePaymentFlow(
                                                    address,
                                                    PaymentRequest(
                                                      address,
                                                      _amountControllers[_selectedOutput].text,
                                                      _memoControllers[_selectedOutput].text,
                                                      "",
                                                      null,
                                                    ),
                                                  );
                                                } finally {
                                                  _justHandledPasteButton = false;
                                                }

                                                _handleLightningInvoicePaste();
                                              },
                                              selectedCurrency:
                                                  widget.sendViewModel.selectedCryptoCurrency,
                                            ),
                                          ],
                                        ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 12,
                                        children: [
                                          // This caption is the amount field's accessible name
                                          // and must stay in the semantics tree:
                                          // NewSendAmountInput deliberately carries no label of
                                          // its own, because labelling the field made Android
                                          // announce the amount twice. Covered by
                                          // test/new-ui/widgets/send_page/send_amount_input_test.dart.
                                          Text(S.of(context).amount),
                                          NewSendAmountInput(
                                            validator: output.sendAll
                                                ? widget.sendViewModel.allAmountValidator
                                                : widget.sendViewModel.amountValidator(output),
                                            amountController: _amountControllers[_selectedOutput],
                                            currency: output.isFiatEntry
                                                ? widget.sendViewModel.fiatCurrency.title
                                                : widget.sendViewModel.selectedCryptoCurrencySymbol,
                                            currencyIconPath: output.isFiatEntry
                                                ? ""
                                                : widget.sendViewModel.selectedCryptoCurrency
                                                        .iconPath ??
                                                    "",
                                            hasPicker: output.isFiatEntry ||
                                                widget.sendViewModel.hasMultipleTokens,
                                            onPickerClicked: () => _presentCurrencyPicker(context),
                                            maxDecimals: output.isFiatEntry
                                                ? widget.sendViewModel.fiatCurrency.decimals
                                                : widget.sendViewModel.useBaseUnits
                                                    ? 0
                                                    : widget.sendViewModel.selectedCryptoCurrency
                                                        .decimals,
                                          ),
                                          FiatAmountBar(
                                            fiatInputMode: output.isFiatEntry,
                                            onSwitchButtonPressed: _onFiatSwitchPressed,
                                            fiatAmount:
                                                _wrapAmount(output.roundedFiatAmount(6), 20),
                                            cryptoAmount:
                                                _wrapAmount(output.roundedCryptoAmount(6), 20),
                                            allAmount: widget.sendViewModel.balance,
                                            cryptoCurrencySymbol:
                                                widget.sendViewModel.selectedCryptoCurrencySymbol,
                                            fiatCurrencySymbol:
                                                widget.sendViewModel.fiatCurrency.symbol,
                                            onAllButtonPressed: () async {
                                              output.setSendAll(
                                                await widget.sendViewModel.sendingBalance,
                                              );
                                              await output.calculateEstimatedFee();
                                            },
                                          ),
                                        ],
                                      ),
                                      if (widget.sendViewModel.isMwebAvailable &&
                                          widget.mode == SendPageModes.normal)
                                        StandardCheckbox(
                                          caption: S.of(context).litecoin_mweb_allow_coins,
                                          captionColor: Theme.of(context).colorScheme.onSurface,
                                          borderColor: Theme.of(context).colorScheme.primary,
                                          iconColor: Theme.of(context).colorScheme.primary,
                                          value: [UnspentCoinType.any, UnspentCoinType.mweb]
                                              .contains(widget.sendViewModel.coinTypeToSpendFrom),
                                          onChanged: (value) =>
                                              widget.sendViewModel.setAllowMwebCoins(value),
                                        ),
                                      if (widget.sendViewModel.hasMemos)
                                        Observer(
                                          builder: (_) => NewSendMemoInput(
                                            memoController: _memoControllers[_selectedOutput],
                                            maxMemoLength: widget.sendViewModel.maxMemoLength,
                                            memoLength: output.memo.length,
                                          ),
                                        ),
                                      if (widget.sendViewModel.hasCoinControl ||
                                          widget.sendViewModel.hasFees)
                                        AnimatedDropdown(
                                          dropdownText: S.of(context).advanced_settings,
                                          content: Column(
                                            children: [
                                              if (widget.sendViewModel.hasFees)
                                                ListItemRegularRowWidget(
                                                  keyValue: "",
                                                  label: S.of(context).fees,
                                                  subtitle:
                                                      "~${output.estimatedFee} ${widget.sendViewModel.currencySymbol} (${output.estimatedFeeFiatAmount} ${widget.sendViewModel.fiatCurrency})",
                                                  // Without fee priorities the row does nothing,
                                                  // so it must not be announced as interactive.
                                                  onTap: widget.sendViewModel.feesViewModel
                                                          .hasFeesPriority
                                                      ? () =>
                                                          pickTransactionPriority(context, output)
                                                      : null,
                                                ),
                                              if (widget.sendViewModel.hasCoinControl)
                                                ListItemRegularRowWidget(
                                                  keyValue: "",
                                                  label: S.of(context).coin_control,
                                                  onTap: () {
                                                    showCupertinoModalBottomSheet(
                                                      enableDrag: false,
                                                      useRootNavigator: true,
                                                      isDismissible: false,
                                                      context: context,
                                                      builder: (context) => NewCoinControlPage(
                                                        unspentCoinsListViewModel: widget
                                                            .sendViewModel
                                                            .unspentCoinsListViewModel,
                                                        canEdit: true,
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              Observer(
                                builder: (_) => Column(
                                  spacing: 12,
                                  children: [
                                    if (!widget.sendViewModel.isReadyForSend)
                                      SendSyncingIndicator(
                                        status: widget.sendViewModel.wallet.syncStatus,
                                      ),
                                    if (widget.sendViewModel.outputs.length > 1)
                                      RecipientDotRow(
                                        numDots: widget.sendViewModel.outputs.length,
                                        onSelected: _setOutput,
                                        selectedDot: _selectedOutput,
                                      ),
                                    Observer(
                                      builder: (_) => NewFuturePrimaryButton(
                                        key: const ValueKey("send_page_send_button_key"),
                                        onPressed: () async {
                                          //Request dummy node to get the focus out of the text fields
                                          FocusScope.of(context).requestFocus(FocusNode());

                                          if (widget.sendViewModel.state is IsExecutingState) {
                                            return;
                                          }

                                          if (widget.mode == SendPageModes.normal) {
                                            await _handleSend();
                                          } else if (widget.mode ==
                                                  SendPageModes.lightningDeposit ||
                                              widget.mode == SendPageModes.mwebDeposit) {
                                            await Navigator.of(context).push(
                                              CupertinoPageRoute(
                                                builder: (context) => Material(
                                                  child: L2ActionWalletSelector(
                                                    showOtherWallets: false,
                                                    action: L2Actions.deposit,
                                                    sendViewModel: widget.sendViewModel,
                                                    contactListViewModel:
                                                        widget.contactListViewModel,
                                                    walletSwitcherViewModel:
                                                        widget.walletSwitcherViewModel,
                                                    onSendInitiated: _handleSend,
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else if (widget.mode ==
                                                  SendPageModes.lightningWithdrawal ||
                                              widget.mode == SendPageModes.mwebWithdrawal) {
                                            await Navigator.of(context).push(
                                              CupertinoPageRoute(
                                                builder: (context) => Material(
                                                  child: L2ActionWalletSelector(
                                                    showOtherWallets: false,
                                                    action: L2Actions.withdraw,
                                                    sendViewModel: widget.sendViewModel,
                                                    contactListViewModel:
                                                        widget.contactListViewModel,
                                                    walletSwitcherViewModel:
                                                        widget.walletSwitcherViewModel,
                                                    onSendInitiated: _handleSend,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        text: S.of(context).continue_text,
                                        color: Theme.of(context).colorScheme.primary,
                                        textColor: Theme.of(context).colorScheme.onPrimary,
                                        disabled: !widget.sendViewModel.isReadyForSend ||
                                            widget.sendViewModel.state is ExecutedSuccessfullyState,
                                      ),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  void _onFiatSwitchPressed() {
    final output = widget.sendViewModel.outputs[_selectedOutput];
    widget.sendViewModel.outputs[_selectedOutput].isFiatEntry = !output.isFiatEntry;

    final amount = output.isFiatEntry ? output.fiatAmount : output.displayCryptoAmount;
    _amountControllers[_selectedOutput].text = amount.startsWith("<") ? "0" : amount;
  }

  void _setOutput(int index) {
    setState(() {
      _selectedOutput = index;
    });
    // final output = widget.sendViewModel.outputs[index];
    // _amountController.text = _fiatInputMode ? output.fiatAmount : output.cryptoAmount;
    // _addressController.text = output.address;
  }

  void _addInputControllers() {
    _amountControllers.add(TextEditingController());
    _addressControllers.add(TextEditingController());
    _memoControllers.add(TextEditingController());

    _amountControllers[_amountControllers.length - 1].addListener(() {
      if (_selectedOutput > widget.sendViewModel.outputs.length - 1) {
        printV(
          "_selectedOutput > widget.sendViewModel.outputs.length - 1! this should NOT happen!",
        );
        return;
      }

      final amount = _amountControllers[_selectedOutput].text.sanitized();
      final output = widget.sendViewModel.outputs[_selectedOutput];

      if (output.isFiatEntry) {
        if (amount != output.fiatAmount) {
          output.sendAll = false;
          output.setFiatAmount(amount);
        }
      } else {
        final isAll = mounted && amount != S.of(context).all;
        if (output.sendAll && isAll) {
          output.sendAll = false;
        }

        if (S.current.all.contains(amount)) {
          return;
        }

        final cAmount = widget.sendViewModel.amountParsingProxy.getDisplayCryptoAmount(
          output.cryptoAmount,
          widget.sendViewModel.selectedCryptoCurrency,
        );
        if (amount != cAmount) {
          final newAmount = widget.sendViewModel.amountParsingProxy
              .getCanonicalCryptoAmount(amount, widget.sendViewModel.selectedCryptoCurrency);
          output.setCryptoAmount(newAmount);
        }
      }
    });

    _addressControllers[_amountControllers.length - 1].addListener(() {
      if (_selectedOutput > widget.sendViewModel.outputs.length - 1) {
        printV(
          "_selectedOutput > widget.sendViewModel.outputs.length - 1! this should NOT happen!",
        );
        return;
      }

      final address = _addressControllers[_selectedOutput].text;
      final output = widget.sendViewModel.outputs[_selectedOutput];

      if (output.address != address && output.extractedAddress != address) {
        output.resetParsedAddress();
        output.address = address;
      }
    });

    _memoControllers[_amountControllers.length - 1].addListener(() {
      if (_selectedOutput > widget.sendViewModel.outputs.length - 1) {
        printV(
          "_selectedOutput > widget.sendViewModel.outputs.length - 1! this should NOT happen!",
        );
        return;
      }
      final memo = _memoControllers[_selectedOutput].text;
      final output = widget.sendViewModel.outputs[_selectedOutput];

      if (memo != output.memo && memo.length <= widget.sendViewModel.maxMemoLength) {
        output.memo = memo;
      }
    });
  }

  Future<void> _handleSend() async {
    //TODO(malik1004x): refactor this action. code was copied over from old ui. i don't like it.

    for (var i = 0; i < widget.sendViewModel.outputs.length; i++) {
      if (i < _amountControllers.length && !widget.sendViewModel.outputs[i].sendAll) {
        if (widget.sendViewModel.outputs[i].isFiatEntry) {
          widget.sendViewModel.outputs[i].setFiatAmount(_amountControllers[i].text);
        } else {
          final amount = widget.sendViewModel.amountParsingProxy.getCanonicalCryptoAmount(
            _amountControllers[i].text.sanitized(),
            widget.sendViewModel.selectedCryptoCurrency,
          );
          widget.sendViewModel.outputs[i].setCryptoAmount(amount);
        }
      }
    }

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      if (widget.sendViewModel.outputs.length > 1) {
        showErrorValidationAlert(context);
      }

      return;
    }

    final notValidItems = widget.sendViewModel.outputs
        .where((item) => item.address.isEmpty || (!item.sendAll && item.cryptoAmount.isEmpty))
        .toList();

    if (notValidItems.isNotEmpty) {
      showErrorValidationAlert(context);
      return;
    }

    if (widget.sendViewModel.wallet.isHardwareWallet) {
      if (!widget.sendViewModel.hardwareWalletViewModel!
          .isConnected(widget.sendViewModel.walletType)) {
        await Navigator.of(context).pushNamed(
          Routes.connectDevices,
          arguments: ConnectDevicePageParams(
            walletType: widget.sendViewModel.walletType,
            hardwareWalletType: widget.sendViewModel.wallet.walletInfo.hardwareWalletType!,
            onConnectDevice: (_, __) {
              widget.sendViewModel.hardwareWalletViewModel!.initWallet(widget.sendViewModel.wallet);
              Navigator.of(context).pop();
            },
            isReconnect: false,
          ),
        );

        // Recheck to handle tap-backs
        if (!widget.sendViewModel.hardwareWalletViewModel!
            .isConnected(widget.sendViewModel.walletType)) {
          return;
        }
      } else {
        await widget.sendViewModel.hardwareWalletViewModel!.initWallet(widget.sendViewModel.wallet);
      }
    }

    if (widget.sendViewModel.wallet.type == WalletType.monero) {
      var amount = Money.zero(widget.sendViewModel.wallet.currency);
      for (final item in widget.sendViewModel.outputs) {
        amount += item.cryptoAmountMoney;
      }
      if (monero!.hasUnknownKeyImages(widget.sendViewModel.wallet) && mounted) {
        await Navigator.of(context).pushNamed(
          Routes.syncKeyImagesDevices,
          arguments: monero!.exportOutputsUR(widget.sendViewModel.wallet),
        );
        await Future.delayed(const Duration(seconds: 1)); // wait for monero to refresh the state
      }
      if (monero!.needExportOutputs(widget.sendViewModel.wallet, amount)) {
        return;
      }
    }

    final check = widget.sendViewModel.shouldDisplayTotp();
    widget.authService.authenticateAction(
      isTransaction: true,
      navigatorKey.currentContext ?? context,
      conditionToDetermineIfToUse2FA: check,
      onAuthSuccess: (value) async {
        if (value) {
          if (!widget.mode.popOnConfirmation && Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          showModalBottomSheet(
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            context: navigatorKey.currentContext ?? context,
            backgroundColor: Colors.transparent,
            builder: (context) => SendConfirmSheet(
              title: widget.mode.title,
              iconPath: widget.mode.helpContent?.imagePath,
              sendViewModel: widget.sendViewModel,
            ),
          ).then((value) {
            if (widget.sendViewModel.state is TransactionCommitted &&
                widget.mode.popOnConfirmation) {
              if (!mounted) {
                return;
              }
              Navigator.of(context, rootNavigator: true).pop();
            }
            widget.sendViewModel.dismissTransaction();
          });

          await widget.sendViewModel.createTransaction();
        }
      },
    );
  }

  void _removeInputControllers(int index) {
    _amountControllers.removeAt(index);
    _addressControllers.removeAt(index);
    _memoControllers.removeAt(index);
  }

  void _presentCurrencyPicker(BuildContext context) {
    final output = widget.sendViewModel.outputs[_selectedOutput];

    if (!output.isFiatEntry && !widget.sendViewModel.hasMultipleTokens) {
      return;
    }

    if (output.isFiatEntry) {
      FiatCurrencyPickerSheet.show(
        context: context,
        selected: widget.sendViewModel.fiatCurrency,
        onSelected: (cur) async {
          widget.sendViewModel.setFiatCurrency(cur);
          await output.calculateEstimatedFee();
        },
      );
      return;
    }

    final isFiatDisabled = widget.sendViewModel.isFiatDisabled;
    final balanceByAsset = <CryptoCurrency, CurrencyPickerBalance>{
      for (final r in widget.sendViewModel.balanceViewModel.formattedBalances)
        r.asset: CurrencyPickerBalance(
          amount: "${r.availableBalance} ${r.asset.title}",
          fiat: isFiatDisabled ? null : "${r.fiatAvailableBalanceRaw} ${r.fiatCurrency?.symbol}",
          fiatValue: isFiatDisabled ? null : double.tryParse(r.fiatAvailableBalanceRaw),
        ),
    };

    CurrencyPickerSheet.show(
      context: context,
      args: CurrencyPickerArgs(
        items: widget.sendViewModel.currencies,
        selected: widget.sendViewModel.selectedCryptoCurrency,
        filterByNetwork: widget.sendViewModel.walletType,
        balanceByAsset: balanceByAsset,
        symbolResolver: widget.sendViewModel.amountParsingProxy.getCryptoSymbol,
        onSelected: (currency) {
          widget.sendViewModel.selectedCryptoCurrency = currency;
          output.calculateEstimatedFee();
        },
      ),
    );
  }

  void _handleLightningInvoicePaste() {
    try {
      final lnAmount = getBolt11Amount(_addressControllers[_selectedOutput].text) ??
          Money.zero(CryptoCurrency.btcln);
      if (!lnAmount.isZero) {
        _amountControllers[_selectedOutput].text =
            widget.sendViewModel.amountParsingProxy.asDisplayString(lnAmount);
      }
    } catch (_) {}
  }

  Future<void> _handlePaymentFlow(String uri, PaymentRequest paymentRequest) async {
    if (uri.contains("@") || paymentRequest.address.contains("@")) {
      return;
    }

    if (OpenCryptoPayService.isOpenCryptoPayQR(uri) &&
        widget.sendViewModel.selectedCryptoCurrency != CryptoCurrency.btcln) {
      final request = await widget.sendViewModel.getOpenCryptoPayRequest(uri);
      if (request == null) {
        return;
      }
      _applyPaymentRequest(request);
      return;
    }

    try {
      final result = await widget.paymentViewModel.processAddress(uri);

      if (paymentRequest.contractAddress != null) {
        await widget.sendViewModel.fetchTokenForContractAddress(paymentRequest.contractAddress!);
      }

      // This automatically switches to lightning mode if you are in a bitcoin wallet
      if (result.addressDetectionResult?.detectedCurrency == CryptoCurrency.btcln) {
        widget.sendViewModel.selectedCryptoCurrency = CryptoCurrency.btcln;
        widget.sendViewModel.coinTypeToSpendFrom = UnspentCoinType.lightning;
      }

      switch (result.type) {
        case PaymentFlowType.singleWallet:
        case PaymentFlowType.multipleWallets:
        case PaymentFlowType.noWallets:
          await _showPaymentConfirmation(
            widget.paymentViewModel,
            widget.walletSwitcherViewModel,
            paymentRequest,
            result,
          );
          break;
        case PaymentFlowType.evmNetworkSelection:
          await _showTokenSelectionFlow(
            widget.paymentViewModel,
            widget.walletSwitcherViewModel,
            paymentRequest,
            fixedNetwork: result.walletType,
          );
          break;
        case PaymentFlowType.solanaTokenSelection:
          await _showTokenSelectionFlow(
            widget.paymentViewModel,
            widget.walletSwitcherViewModel,
            paymentRequest,
            fixedNetwork: WalletType.solana,
          );
          break;
        case PaymentFlowType.tronTokenSelection:
          await _showTokenSelectionFlow(
            widget.paymentViewModel,
            widget.walletSwitcherViewModel,
            paymentRequest,
            fixedNetwork: WalletType.tron,
          );

          break;
        case PaymentFlowType.currentWalletCompatible:
        case PaymentFlowType.error:
        case PaymentFlowType.incompatible:
          _applyPaymentRequest(paymentRequest);
          break;
      }
    } catch (e) {
      printV("Payment flow error: $e");
      _applyPaymentRequest(paymentRequest);
    }
  }

  Future<void> _showPaymentConfirmation(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
    PaymentFlowResult result,
  ) async {
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => PaymentConfirmationBottomSheet(
        paymentFlowResult: result,
        paymentViewModel: paymentViewModel,
        walletSwitcherViewModel: walletSwitcherViewModel,
        paymentRequest: paymentRequest,
        onSelectWallet: () => _handleSelectWallet(
          paymentViewModel,
          walletSwitcherViewModel,
          paymentRequest,
          result,
        ),
        onChangeWallet: () => _handleChangeWallet(
          paymentViewModel,
          walletSwitcherViewModel,
          paymentRequest,
          result,
        ),
        onSwap: (bottomSheetContext) =>
            _handleSwapFlow(paymentViewModel, result, bottomSheetContext),
        onSwitchNetwork: () => _handleSwitchNetwork(
          paymentViewModel,
          walletSwitcherViewModel,
          paymentRequest,
          result,
        ),
      ),
    );
  }

  Future<void> _showTokenSelectionFlow(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest, {
    WalletType? fixedNetwork,
  }) async {
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => TokenSelectionBottomSheet(
        paymentViewModel: paymentViewModel,
        paymentRequest: paymentRequest,
        fixedNetwork: fixedNetwork,
        onNext: (newResult) {
          final selectedChainId = newResult.chainId;
          final isCompatible =
              selectedChainId == evm?.getSelectedChainId(widget.sendViewModel.wallet);

          if (isCompatible) {
            widget.sendViewModel.setSelectedCryptoCurrency(
              newResult.addressDetectionResult!.detectedCurrency!.title,
            );
            _applyPaymentRequest(paymentRequest);
          } else {
            _showPaymentConfirmation(
              paymentViewModel,
              walletSwitcherViewModel,
              paymentRequest,
              newResult,
            );
          }
        },
      ),
    );
  }

  Future<void> _handleSelectWallet(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
    PaymentFlowResult result,
  ) async {
    Navigator.of(context).pop();

    await showModalBottomSheet<WalletInfo>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (dialogContext) => WalletSwitcherBottomSheet(
        viewModel: walletSwitcherViewModel,
        filterWalletType: paymentViewModel.detectedWalletType,
      ),
    );

    final success = await walletSwitcherViewModel.switchToSelectedWallet();

    if (success) {
      if (isEVMCompatibleChain(widget.sendViewModel.wallet.type) && result.chainId != null) {
        final appStore = getIt.get<AppStore>();
        final node = appStore.settingsStore.getCurrentNode(
          widget.sendViewModel.wallet.type,
          chainId: result.chainId,
        );
        await evm!.selectChain(widget.sendViewModel.wallet, result.chainId!, node: node);
      }

      await widget.sendViewModel.wallet.updateBalance();

      final detectedCurrency = result.addressDetectionResult!.detectedCurrency;
      if (detectedCurrency != null) {
        widget.sendViewModel.setSelectedCryptoCurrency(detectedCurrency.title);
      }

      _applyPaymentRequest(paymentRequest);
    }
  }

  Future<void> _handleChangeWallet(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
    PaymentFlowResult result,
  ) async {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (result.type == PaymentFlowType.singleWallet && result.wallet != null) {
      walletSwitcherViewModel.selectWallet(result.wallet!);
      final success = await walletSwitcherViewModel.switchToSelectedWallet();
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (context) {
                loadingBottomSheetContext = context;
                return LoadingBottomSheet(
                  titleText: S.of(context).loading_your_wallet,
                );
              },
            );
          }
        });

        // If EVM wallet and chainId is specified, switch to that chain
        if (isEVMCompatibleChain(widget.sendViewModel.wallet.type) && result.chainId != null) {
          final appStore = getIt.get<AppStore>();
          final node = appStore.settingsStore.getCurrentNode(
            widget.sendViewModel.wallet.type,
            chainId: result.chainId,
          );
          await evm!.selectChain(widget.sendViewModel.wallet, result.chainId!, node: node);
        }

        await Future.delayed(const Duration(seconds: 2));
        if (loadingBottomSheetContext != null &&
            loadingBottomSheetContext!.mounted &&
            Navigator.canPop(loadingBottomSheetContext!)) {
          Navigator.of(loadingBottomSheetContext!).pop();
        }

        await widget.sendViewModel.wallet.updateBalance();
        widget.sendViewModel
            .setSelectedCryptoCurrency(result.addressDetectionResult!.detectedCurrency!.title);
        _applyPaymentRequest(paymentRequest);
      }
    } else if (result.wallets.isNotEmpty && result.wallets.length == 1) {
      walletSwitcherViewModel.selectWallet(result.wallets.first);
      final success = await walletSwitcherViewModel.switchToSelectedWallet();
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (context) {
                loadingBottomSheetContext = context;
                return LoadingBottomSheet(
                  titleText: S.of(context).loading_your_wallet,
                );
              },
            );
          }
        });

        // If EVM wallet and chainId is specified, switch to that chain
        if (isEVMCompatibleChain(widget.sendViewModel.wallet.type) && result.chainId != null) {
          final appStore = getIt.get<AppStore>();
          final node = appStore.settingsStore.getCurrentNode(
            widget.sendViewModel.wallet.type,
            chainId: result.chainId,
          );
          await evm!.selectChain(widget.sendViewModel.wallet, result.chainId!, node: node);
        }

        await Future.delayed(const Duration(seconds: 2));
        if (loadingBottomSheetContext != null && loadingBottomSheetContext!.mounted) {
          Navigator.of(loadingBottomSheetContext!).pop();
        }

        await widget.sendViewModel.wallet.updateBalance();
        widget.sendViewModel
            .setSelectedCryptoCurrency(result.addressDetectionResult!.detectedCurrency!.title);
        _applyPaymentRequest(paymentRequest);
      }
    }
  }

  Future<void> _handleSwitchNetwork(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
    PaymentFlowResult result,
  ) async {
    if (result.type != PaymentFlowType.evmNetworkSelection || result.wallet == null) {
      return;
    }

    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (context) {
              loadingBottomSheetContext = context;
              return LoadingBottomSheet(titleText: S.of(context).loading_your_wallet);
            },
          );
        }
      });

      await paymentViewModel.selectChain();

      await Future.delayed(const Duration(seconds: 2));
      if (loadingBottomSheetContext != null && loadingBottomSheetContext!.mounted) {
        Navigator.of(loadingBottomSheetContext!).pop();
      }

      await widget.sendViewModel.wallet.updateBalance();
      final detectedCurrency = result.addressDetectionResult?.detectedCurrency;
      if (detectedCurrency != null) {
        widget.sendViewModel.setSelectedCryptoCurrency(detectedCurrency.title);
      }
      _applyPaymentRequest(paymentRequest);
    } catch (e) {
      if (loadingBottomSheetContext != null && loadingBottomSheetContext!.mounted) {
        Navigator.of(loadingBottomSheetContext!).pop();
      }
      printV("Switch network error: $e");
    }
  }

  /// Apply payment request to current form
  void _applyPaymentRequest(PaymentRequest paymentRequest) {
    if (widget.sendViewModel.usePayjoin) {
      widget.sendViewModel.payjoinUri = paymentRequest.pjUri;
    }
    _addressControllers[_selectedOutput].text = paymentRequest.address;
    if (paymentRequest.amount.isNotEmpty) {
      try {
        _amountControllers[_selectedOutput].text =
            widget.sendViewModel.amountParsingProxy.getDisplayCryptoAmount(
          paymentRequest.amount,
          widget.sendViewModel.selectedCryptoCurrency,
        );
      } catch (e) {}
    }
    // _memoControllers[_selectedOutput].text = paymentRequest.note;

    _applyNote(paymentRequest.note, _selectedOutput);
  }

  Future<void> _handleSwapFlow(
    PaymentViewModel paymentViewModel,
    PaymentFlowResult result,
    BuildContext bottomSheetContext,
  ) async {
    Navigator.of(bottomSheetContext).pop();

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) {
      return;
    }

    final bottomSheet = getIt.get<SwapConfirmationBottomSheet>(param1: result);
    await showModalBottomSheet<Trade?>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => bottomSheet,
    );
  }

  void showErrorValidationAlert(BuildContext context) {
    int emptyAddressIndex = -1;
    for (int i = 0; i < widget.sendViewModel.outputs.length; i++) {
      if (widget.sendViewModel.outputs[i].address.isEmpty) {
        emptyAddressIndex = i;
        break;
      }
    }

    showPopUp<void>(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: S.of(context).error,
        alertContent: emptyAddressIndex == -1
            ? S.of(context).check_receiver_forms
            : S.of(context).enter_recipient_address,
        buttonText: S.of(context).ok,
        buttonAction: () => Navigator.of(context).pop(),
      ),
    );
    if (emptyAddressIndex != -1) {
      _setOutput(emptyAddressIndex);
    }
  }

  bool isRegularElectrumAddress(String address) {
    final supportedTypes = [CryptoCurrency.btc, CryptoCurrency.ltc, CryptoCurrency.bch];
    final excludedPatterns = [
      RegExp(AddressValidator.silentPaymentAddressPatternMainnet),
      RegExp(AddressValidator.silentPaymentAddressPatternTestnet),
      RegExp(AddressValidator.mWebAddressPattern),
      RegExp(AddressValidator.bolt11InvoiceMatcher),
    ];

    final trimmed = address.trim();

    bool isValid = false;
    for (final type in supportedTypes) {
      final addressPattern = AddressValidator.getAddressFromStringPattern(type);
      if (addressPattern != null) {
        final regex = RegExp("^$addressPattern\$");
        if (regex.hasMatch(trimmed)) {
          isValid = true;
          break;
        }
      }
    }

    for (final pattern in excludedPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return false;
      }
    }

    return isValid;
  }

  Future<void> pickTransactionPriority(BuildContext pageContext, Output output) async {
    final items = priorityForWalletType(widget.sendViewModel.walletType);
    final selectedItem = items.indexOf(widget.sendViewModel.feesViewModel.transactionPriority);
    final customItemIndex = widget.sendViewModel.feesViewModel.getCustomPriorityIndex(items);
    final isBitcoinWallet = widget.sendViewModel.walletType == WalletType.bitcoin;
    final maxCustomFeeRate = widget.sendViewModel.feesViewModel.maxCustomFeeRate?.toDouble();

    FocusManager.instance.primaryFocus?.unfocus();

    await showCupertinoModalBottomSheet(
      context: pageContext,
      expand: false,
      builder: (modalContext) {
        int selectedIdx = selectedItem;
        return Observer(
          builder: (context) {
            final customFeeRate = isBitcoinWallet
                ? widget.sendViewModel.feesViewModel.customBitcoinFeeRate.toDouble()
                : null;
            return StatefulBuilder(
              builder: (context, setState) => IntrinsicHeight(
                // height: MediaQuery.of(context).size.height*0.4,
                child: ModalNavigator(
                  parentContext: modalContext,
                  heightMode: ModalHeightModes.natural,
                  rootPage: Material(
                    child: NewPicker(
                      title: S.of(context).set_fees,
                      description: S.of(context).set_fees_desc,
                      sliderPageTitle: S.of(context).custom_fee,
                      sliderInitialValue: customFeeRate,
                      sliderMaxValue: maxCustomFeeRate,
                      sliderValueDescription: "sat/byte",
                      items: items
                          .map(
                            (item) => PickerItem<TransactionPriority>(
                              title: item.title,
                              subtitle: item.description,
                              hint: item.hint,
                              value: item,
                              isSliderItem: items.indexOf(item) == customItemIndex,
                            ),
                          )
                          .toList(),
                      onItemSelected: (priority) async {
                        widget.sendViewModel.feesViewModel.setTransactionPriority(priority);
                        setState(() => selectedIdx = items.indexOf(priority));
                        await output.calculateEstimatedFee();
                      },
                      onSliderChanged: (value) {
                        widget.sendViewModel.feesViewModel.customBitcoinFeeRate = value.round();
                      },
                      selectedIndex: selectedIdx,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _wrapAmount(String amount, int maxChars) =>
      amount.length <= maxChars ? amount : "${amount.substring(0, maxChars - 3)}...";

  // TODO: make a separate variable for memo in payment request model
  void _applyNote(String note, int selectedOutput) {
    if (widget.sendViewModel.hasMemos && note.length <= widget.sendViewModel.maxMemoLength) {
      widget.sendViewModel.outputs[selectedOutput].memo = note;
    } else {
      widget.sendViewModel.outputs[selectedOutput].note = note;
    }
  }
}

class SendHelpPage extends StatelessWidget {
  const SendHelpPage({required this.content, super.key});

  final SendPageHelpContent content;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ModalTopBar(
              title: content.title,
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: Navigator.of(context).pop,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                spacing: 12,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CakeImageWidget(imageUrl: content.imagePath),
                  Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (content.disclaimer != null) ...[
                    const SizedBox(),
                    const SizedBox(),
                    Text(
                      content.disclaimer!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: NewPrimaryButton(
                onPressed: Navigator.of(context).pop,
                text: S.of(context).i_understand,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
}

Future<bool> showParsedAddressConfirmationAlert(
  BuildContext context,
  ParsedAddress parsedAddress,
) async {
  final confirmed = await showPopUp<bool>(
    context: context,
    builder: (context) => AlertWithOneAction(
      alertTitle: S.of(context).address_detected,
      headerTitleText: parsedAddress.profileName.isEmpty ? null : parsedAddress.profileName,
      headerImageProfileUrl: parsedAddress.profileImageUrl.isEmpty
          ? parsedAddress.addressSource.iconPath
          : parsedAddress.profileImageUrl,
      alertContent: S.of(context).extracted_address_content(
            "${parsedAddress.handle} (${parsedAddress.addressSource.label})",
          ),
      buttonText: S.of(context).ok,
      buttonAction: () => Navigator.of(context).pop(true),
    ),
  );

  return confirmed ?? false;
}
