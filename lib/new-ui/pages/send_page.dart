
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/widgets/animated_dropdown.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/new-ui/widgets/picker.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/fiat_amount_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/token_selection_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart';
import 'package:cake_wallet/store/app_store.dart';
import "package:cw_core/wallet_type.dart";
import 'package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/recipient_dot_row.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_syncing_indicator.dart';
import 'package:cake_wallet/routes.dart' show Routes;
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/payment_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/swap_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/wallet_switcher_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';

import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/l2_action_wallet_selector.dart';
import 'package:cake_wallet/view_model/contact_list/contact_list_view_model.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SendPageHelpContent {
  final String imagePath;
  final String title;
  final String description;
  final String? disclaimer;

  const SendPageHelpContent({required this.title, required this.imagePath, required this.description,this.disclaimer});
}

class SendPageModes {
  final bool showAddressField;
  final String title;
  final String? description;
  final SendPageHelpContent? helpContent;
  final bool showConfirmationAsModal;

  const SendPageModes({required this.title, this.description, required this.showAddressField,this.helpContent, this.showConfirmationAsModal=true}
      );

  static final SendPageModes normal = SendPageModes(title: S.current.send, showAddressField: true);


  static final SendPageModes l2deposit = SendPageModes(
      title: S.current.bitcoin_lightning_deposit,
      description: S.current.to_lightning,
      showAddressField: false,
      helpContent: SendPageHelpContent(
          title: S.current.bitcoin_lightning_deposit,
          imagePath: "assets/new-ui/lightning_deposit_help.svg",
          description: S.current.lightning_deposit_desc,
          disclaimer: S.current.lightning_deposit_disclaimer),
      showConfirmationAsModal: false);


  static final SendPageModes l2withdrawal = SendPageModes(
      title: S.current.bitcoin_lightning_withdraw,
      description: S.current.to_on_chain,
      showAddressField: false,
      helpContent: SendPageHelpContent(
          title: S.current.bitcoin_lightning_withdraw,
          imagePath: "assets/new-ui/lightning_withdraw_help.svg",
          description: S.current.lightning_withdraw_desc,
          disclaimer: S.current.lightning_withdraw_disclaimer),
      showConfirmationAsModal: false);

  static final all = [
    normal,
    l2deposit,
    l2withdrawal,
  ];
}

class SendPageParams {
  final PaymentRequest? initialPaymentRequest;
  final SendPageModes mode;
  final UnspentCoinType unspentCoinType;

  SendPageParams({
    this.initialPaymentRequest,
    SendPageModes? mode,
    this.unspentCoinType = UnspentCoinType.any,
  }) : mode = mode ?? SendPageModes.normal;
}

class NewSendPage extends StatefulWidget {
  NewSendPage(
      {super.key,
        required this.sendViewModel,
        required this.paymentViewModel,
        required this.walletSwitcherViewModel,
        required this.contactListViewModel,
        required this.authService,
        required SendPageParams params})
      : initialPaymentRequest = params.initialPaymentRequest,
        mode = params.mode;

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
  bool _fiatInputMode = false;
  int _selectedOutput = 0;


  List<TextEditingController> _amountControllers = [];
  List<TextEditingController> _addressControllers = [];
  BuildContext? loadingBottomSheetContext;
  BuildContext? dialogContext;
  ContactRecord? newContactAddress;

  @override
  void initState() {
    super.initState();
    _addInputControllers();


    reaction((_) => widget.sendViewModel.outputs[_selectedOutput].sendAll, ((bool all) {
      if (all) {
        _fiatInputMode = false;
        _amountControllers[_selectedOutput].text = S.current.all;
      }
    }));

    reaction((_)=>widget.sendViewModel.outputs[_selectedOutput].address, ((address) {
      _addressControllers[_selectedOutput].text = address;
    }));

    if (widget.initialPaymentRequest != null &&
        widget.sendViewModel.walletCurrencyName == widget.initialPaymentRequest!.scheme.toLowerCase()) {
      _addressControllers[0].text = widget.initialPaymentRequest!.address;
      _amountControllers[0].text = widget.initialPaymentRequest!.amount;
    }

    /// if the current wallet doesn't match the one in the qr code
    if (widget.initialPaymentRequest != null &&
        widget.sendViewModel.walletCurrencyName != widget.initialPaymentRequest!.scheme.toLowerCase()) {
      WidgetsBinding.instance.addPostFrameCallback(
            (timeStamp) {
          if (mounted) {
            final prefix =
            widget.initialPaymentRequest!.scheme.isNotEmpty ? "${widget.initialPaymentRequest!.scheme}:" : "";
            final amount = widget.initialPaymentRequest!.amount.isNotEmpty
                ? "?amount=${widget.initialPaymentRequest!.amount}"
                : "";
            final uri = prefix + widget.initialPaymentRequest!.address + amount;
            _handlePaymentFlow(uri, widget.initialPaymentRequest!);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {


    return Observer(
      builder: (_) {
        final output = widget.sendViewModel.outputs[_selectedOutput];
        return SafeArea(
          bottom: false,
          child: KeyboardHideOverlay(
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SafeArea(
                child: Column(
                  spacing: 12,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ModalTopBar(
                      title: widget.mode.title,
                      subtitle: widget.mode.description,
                      leadingIcon: Icon(Icons.close),
                      onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                  trailingWidget: Observer(
                    builder:(_)=> Row(
                      spacing: 8,
                      children: [
                        if (widget.sendViewModel.outputs.length > 1)
                          ModernButton(
                              size: 36,
                              icon: SvgPicture.asset(
                                "assets/new-ui/remove_recipient.svg",
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.primary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onPressed: () {
                                final outputIndex = _selectedOutput;
                                if (_selectedOutput != 0) {
                                  _setOutput(_selectedOutput - 1);
                                } else {
                                  _setOutput(1);
                                }
                                _removeInputControllers(outputIndex);
                                widget.sendViewModel.removeOutput(output);
                                if (outputIndex == 0) _setOutput(0);
                              }),
                        if(widget.mode == SendPageModes.normal)
                          ModernButton(
                              size: 36,
                              icon: Icon(Icons.add),
                              iconColor: Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                _addInputControllers();
                                widget.sendViewModel.addOutput();
                                _setOutput(widget.sendViewModel.outputs.length - 1);
                              }),
                        if(widget.mode.helpContent != null)
                          ModernButton(
                              size:36,
                              icon:SvgPicture.asset("assets/new-ui/help.svg",colorFilter:ColorFilter.mode(Theme.of(context).colorScheme.primary,BlendMode.srcIn),),
                              onPressed:(){Navigator.of(context).push(CupertinoPageRoute(builder: (context) => Material(child: SendHelpPage(content: widget.mode.helpContent!))));
                              }
                          )
                      ],
                    ),
                  ),),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            DirectionalAnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Column(
                                key: ValueKey(_selectedOutput),
                                spacing: 24,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if(widget.mode.showAddressField)
                                  Column(crossAxisAlignment:CrossAxisAlignment.start,
                                    spacing:12,children: [
                                    Text(S.of(context).address_or_alias),
                                    NewSendAddressInput(
                                      addressController: _addressControllers[_selectedOutput],
                                      onURIScanned: (uri) async {
                                        output.resetParsedAddress();
                                        await output.fetchParsedAddress(context);

                                        // Process the payment through the new flow
                                        await _handlePaymentFlow(
                                          uri.toString(),
                                          PaymentRequest.fromUri(uri),
                                        );
                                      },
                                      onEditingComplete: (){
                                        output.fetchParsedAddress(context).then((val){
                                          if(_addressControllers[_selectedOutput].text != output.extractedAddress) {
                                            _addressControllers[_selectedOutput].text = output.extractedAddress;
                                          }
                                        });
                                      },
                                      onPushAddressBookButton: (context) async {
                                        output.resetParsedAddress();
                                      },
                                      onSelectedContact: (contact) {
                                        output.loadContact(contact);
                                      },
                                      selectedCurrency: widget.sendViewModel.selectedCryptoCurrency,
                                    ),
                                  ],
                                  ),
                    Column(crossAxisAlignment:CrossAxisAlignment.start,spacing:12,children: [
            Text(S.of(context).amount),
            NewSendAmountInput(
                    amountController: _amountControllers[_selectedOutput],
                    currency: _fiatInputMode
              ? widget.sendViewModel.fiatCurrency.title
              : widget.sendViewModel.selectedCryptoCurrency.title,
                    currencyIconPath: _fiatInputMode
              ? ""
              : widget.sendViewModel.selectedCryptoCurrency.iconPath ?? "",
                    hasPicker: (_fiatInputMode || widget.sendViewModel.hasMultipleTokens),
                    onPickerClicked: () {
            _presentCurrencyPicker(context);
                    },
            ),
                                    FiatAmountBar(
                                      fiatInputMode: _fiatInputMode,
                                      onSwitchButtonPressed: () {
                                        setState(() {
                                          _fiatInputMode = !_fiatInputMode;
                                          _amountControllers[_selectedOutput].text = _fiatInputMode
                                              ? output.fiatAmount
                                              : output.cryptoAmount;
                                        });
                                      },
                                      fiatAmount: _wrapAmount(output.roundedFiatAmount(6), 20),
                                      cryptoAmount: _wrapAmount(output.roundedCryptoAmount(6), 20),
                                      allAmount: widget.sendViewModel.balance,
                                      cryptoCurrency:
                                          widget.sendViewModel.selectedCryptoCurrency.title,
                                      fiatCurrency: widget.sendViewModel.fiatCurrency.title,
                                      onAllButtonPressed: () async {
                                        output.setSendAll(await widget.sendViewModel.sendingBalance);
                                      },
                                    ),
                                  ],
                                ),
                                AnimatedDropdown(
                                    dropdownText: S.of(context).advanced_settings,
                                    content: Column(children: [
                                      if (widget.sendViewModel.hasFees)
                  ListItemRegularRowWidget(
                    keyValue: "",
                    label: S.of(context).fees,
                    subtitle: "~${output.estimatedFee} ${widget.sendViewModel.currency} (${output.estimatedFeeFiatAmount} ${widget.sendViewModel.fiatCurrency})",

        onTap: () {
          if (widget.sendViewModel.feesViewModel.hasFeesPriority)
            pickTransactionPriority(context, output);
        },
      ),
      if(widget.sendViewModel.hasCoinControl)
      ListItemRegularRowWidget(
        keyValue: "",
        label: "Coin Control",
        onTap: () {
          Navigator.of(context).pushNamed(Routes.unspentCoinsList);
        },
      )
  ]))

                                ],
                              ),
                            ),
                            Observer(
                              builder: (_) => Column(
                                spacing: 12,
                                children: [
                                  if (!widget.sendViewModel.isReadyForSend)
                                    SendSyncingIndicator(status: widget.sendViewModel.wallet.syncStatus),
                                  if (widget.sendViewModel.outputs.length > 1)
                                    RecipientDotRow(
                                      numDots: widget.sendViewModel.outputs.length,
                                      onSelected: _setOutput,
                                      selectedDot: _selectedOutput,
                                    ),
                                  Observer(
                                    builder: (_) {
                                      return LoadingPrimaryButton(
                                        key: ValueKey('send_page_send_button_key'),
                                        onPressed: () async {
                                          //Request dummy node to get the focus out of the text fields
                                          FocusScope.of(context).requestFocus(FocusNode());

                                          if (widget.sendViewModel.state is IsExecutingState) return;

                                          if(widget.mode == SendPageModes.normal) {
                                            _handleSend();
                                          } else if(widget.mode == SendPageModes.l2deposit) {
                                            Navigator.of(context).push(CupertinoPageRoute(builder: (context) => Material(child: L2ActionWalletSelector(
                                              showOtherWallets: false,
                                              action: l2actions.deposit,
                                              sendViewModel: widget.sendViewModel,
                                              contactListViewModel: widget.contactListViewModel,
                                              walletSwitcherViewModel: widget.walletSwitcherViewModel,
                                              onSendInitiated: _handleSend,
                                            ))));
                                          } else if(widget.mode == SendPageModes.l2withdrawal) {
                                            Navigator.of(context).push(CupertinoPageRoute(builder: (context) => Material(child: L2ActionWalletSelector(
                                              showOtherWallets: false,
                                              action: l2actions.withdraw,
                                              sendViewModel: widget.sendViewModel,
                                              contactListViewModel: widget.contactListViewModel,
                                              walletSwitcherViewModel: widget.walletSwitcherViewModel,
                                              onSendInitiated: _handleSend,
                                            ))));
                                          }
                                        },
                                        text: S.of(context).continue_text,
                                        color: Theme.of(context).colorScheme.primary,
                                        textColor: Theme.of(context).colorScheme.onPrimary,
                                        isLoading: widget.sendViewModel.state is IsExecutingState ||
                                            widget.sendViewModel.state is TransactionCommitting ||
                                            widget.sendViewModel.state is IsAwaitingDeviceResponseState ||
                                            widget.sendViewModel.state is LoadingTemplateExecutingState,
                                        isDisabled: !widget.sendViewModel.isReadyForSend ||
                                            widget.sendViewModel.state is ExecutedSuccessfullyState,
                                      );
                                    },
                                  ),
                                  SizedBox(),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
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

    _amountControllers[_amountControllers.length-1].addListener(() {
      if (_selectedOutput > widget.sendViewModel.outputs.length - 1) {
        printV(
            "_selectedOutput > widget.sendViewModel.outputs.length - 1! this should NOT happen!");
        return;
      }

      final amount = _amountControllers[_selectedOutput].text;
      final output = widget.sendViewModel.outputs[_selectedOutput];

      if (_fiatInputMode) {
        if (amount != output.fiatAmount) {
          output.sendAll = false;
          output.setFiatAmount(amount);
        }
      } else {
        if (output.sendAll && amount != S.of(context).all) {
          output.sendAll = false;
        }

        if (S.current.all.contains(amount)) return;

        final cAmount = widget.sendViewModel.amountParsingProxy
            .getDisplayCryptoAmount(output.cryptoAmount, widget.sendViewModel.selectedCryptoCurrency);
        if (amount != cAmount) {
          final newAmount = widget.sendViewModel.amountParsingProxy
              .getCanonicalCryptoAmount(amount, widget.sendViewModel.selectedCryptoCurrency);
          output.setCryptoAmount(newAmount);
        }
      }
    });

    _addressControllers[_amountControllers.length-1].addListener(() {
      if (_selectedOutput > widget.sendViewModel.outputs.length - 1) {
        printV(
            "_selectedOutput > widget.sendViewModel.outputs.length - 1! this should NOT happen!");
        return;
      }

      final address = _addressControllers[_selectedOutput].text;
      final output = widget.sendViewModel.outputs[_selectedOutput];

      if (output.address != address) {
        output.resetParsedAddress();
        output.address = address;
      }
    });
  }

  void _handleSend() async {
    //TODO refactor this action. code was copied over from old ui. i don't like it.

    // if (_formKey.currentState != null &&
    //     !_formKey.currentState!.validate()) {
    //   if (sendViewModel.outputs.length > 1) {
    //     showErrorValidationAlert(context);
    //   }
    //
    //   return;
    // }

    final notValidItems = widget.sendViewModel.outputs
        .where((item) =>
    item.address.isEmpty || item.cryptoAmount.isEmpty)
        .toList();

    if (notValidItems.isNotEmpty) {
      showErrorValidationAlert(context);
      return;
    }

    if (widget.sendViewModel.wallet.isHardwareWallet) {
      if (!widget
          .sendViewModel.hardwareWalletViewModel!.isConnected) {
        await Navigator.of(context).pushNamed(Routes.connectDevices,
            arguments: ConnectDevicePageParams(
              walletType: widget.sendViewModel.walletType,
              hardwareWalletType: widget.sendViewModel.wallet
                  .walletInfo.hardwareWalletType!,
              onConnectDevice: (BuildContext context, _) {
                widget.sendViewModel.hardwareWalletViewModel!
                    .initWallet(widget.sendViewModel.wallet);
                Navigator.of(context).pop();
              },
            ));
      } else {
        widget.sendViewModel.hardwareWalletViewModel!
            .initWallet(widget.sendViewModel.wallet);
      }
    }

    if (widget.sendViewModel.wallet.type == WalletType.monero) {
      int amount = 0;
      for (var item in widget.sendViewModel.outputs) {
        amount += item.formattedCryptoAmount;
      }
      if (monero!
          .needExportOutputs(widget.sendViewModel.wallet, amount)) {
        await Navigator.of(context).pushNamed(Routes.urqrAnimatedPage,
            arguments:
            monero!.exportOutputsUR(widget.sendViewModel.wallet));
        await Future.delayed(Duration(
            seconds: 1)); // wait for monero to refresh the state
      }
      if (monero!
          .needExportOutputs(widget.sendViewModel.wallet, amount)) {
        return;
      }
    }

    final check = widget.sendViewModel.shouldDisplayTotp();
    widget.authService.authenticateAction(
      navigatorKey.currentContext??context,
      conditionToDetermineIfToUse2FA: check,
      onAuthSuccess: (value) async {
        if (value) {
          if (widget.mode.showConfirmationAsModal) {
            showModalBottomSheet(
                isScrollControlled: true,
                context: navigatorKey.currentContext ?? context,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return SendConfirmSheet(
                    title: widget.mode.title,
                    iconPath: widget.mode.helpContent?.imagePath,
                    sendViewModel: widget.sendViewModel,
                  );
                }).then((value) async {
              if (widget.sendViewModel.state is TransactionCommitted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              widget.sendViewModel.dismissTransaction();
            });
          } else {
            Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) => Material(
                    child: SendConfirmSheet(
                      title: widget.mode.title,
                      iconPath: widget.mode.helpContent?.imagePath,
                      isPage: true,
                      sendViewModel: widget.sendViewModel,
                    )))).then((value) async {
              widget.sendViewModel.dismissTransaction();
            });
          }

          await widget.sendViewModel.createTransaction();
        }
      },
    );
  }

  void _removeInputControllers(int index) {
    _amountControllers.removeAt(index);
    _addressControllers.removeAt(index);
  }

  void _presentCurrencyPicker(BuildContext context) {
    if (!_fiatInputMode && !widget.sendViewModel.hasMultipleTokens) {
      return;
    }

    final output = widget.sendViewModel.outputs[_selectedOutput];

    showPopUp<void>(
      context: context,
      builder: (_) => CurrencyPicker(
        key: ValueKey('send_page_currency_picker_dialog_button_key'),
        selectedAtIndex: _fiatInputMode
            ? widget.sendViewModel.fiatCurrencies.indexOf(widget.sendViewModel.fiatCurrency)
            : widget.sendViewModel.currencies.indexOf(widget.sendViewModel.selectedCryptoCurrency),
        items:
        _fiatInputMode ? widget.sendViewModel.fiatCurrencies : widget.sendViewModel.currencies,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency cur) async {
          late final selectedCurrency;
          if (_fiatInputMode) {
            selectedCurrency = widget.sendViewModel.setFiatCurrency(cur as FiatCurrency);
          } else {
            selectedCurrency =
                widget.sendViewModel.selectedCryptoCurrency = (cur as CryptoCurrency);
          }
          await output.calculateEstimatedFee();
          return selectedCurrency;
        },
      ),
    );
  }
  Future<void> _handlePaymentFlow(String uri, PaymentRequest paymentRequest) async {
    if (uri.contains('@') || paymentRequest.address.contains('@')) return;

    if (OpenCryptoPayService.isOpenCryptoPayQR(uri)) {
      widget.sendViewModel.createOpenCryptoPayTransaction(uri);
      return;
    }

    try {
      final result = await widget.paymentViewModel.processAddress(uri);

      if (paymentRequest.contractAddress != null) {
        await widget.sendViewModel.fetchTokenForContractAddress(paymentRequest.contractAddress!);
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
    if (!context.mounted) {
      return;
    }

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
        );
      },
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
      builder: (BuildContext context) {
        return TokenSelectionBottomSheet(
          paymentViewModel: paymentViewModel,
          paymentRequest: paymentRequest,
          fixedNetwork: fixedNetwork,
          onNext: (PaymentFlowResult newResult) {
            final selectedChainId = newResult.chainId;
            final isCompatible = selectedChainId == evm!.getSelectedChainId(widget.sendViewModel.wallet);

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
        );
      },
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
      builder: (BuildContext dialogContext) {
        return WalletSwitcherBottomSheet(
          viewModel: walletSwitcherViewModel,
          filterWalletType: paymentViewModel.detectedWalletType,
        );
      },
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
              builder: (BuildContext context) {
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
              builder: (BuildContext context) {
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
    if (result.type != PaymentFlowType.evmNetworkSelection || result.wallet == null) return;

    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    try {
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
      printV('Switch network error: $e');
    }
  }

  /// Apply payment request to current form
  void _applyPaymentRequest(PaymentRequest paymentRequest) {
    if (widget.sendViewModel.usePayjoin) {
      widget.sendViewModel.payjoinUri = paymentRequest.pjUri;
    }
    _addressControllers[_selectedOutput].text = paymentRequest.address;
    if (paymentRequest.amount.isNotEmpty) {
      _amountControllers[_selectedOutput].text = paymentRequest.amount;
    }
    // TODO: add notes
    // noteController.text = paymentRequest.note;
  }

  Future<void> _handleSwapFlow(
      PaymentViewModel paymentViewModel,
      PaymentFlowResult result,
      BuildContext bottomSheetContext,
      ) async {
    Navigator.of(bottomSheetContext).pop();

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final bottomSheet = getIt.get<SwapConfirmationBottomSheet>(param1: result);
    await showModalBottomSheet<Trade?>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) => bottomSheet,
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
      builder: (context) =>
          AlertWithOneAction(
            alertTitle: S
                .of(context)
                .error,
            alertContent: emptyAddressIndex == -1
                ? S.of(context).check_receiver_forms
                : S.of(context).enter_recipient_address,
            buttonText: S
                .of(context)
                .ok,
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
        final regex = RegExp('^$addressPattern\$');
        if (regex.hasMatch(trimmed)) {
          isValid = true;
          break;
        }
      }
    }

    for (final pattern in excludedPatterns) {
      if (pattern.hasMatch(trimmed)) return false;
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
      builder: (BuildContext modalContext) {
        int selectedIdx = selectedItem;
        return Observer(
            builder: (context) {
              double? customFeeRate =
              isBitcoinWallet ? widget.sendViewModel.feesViewModel.customBitcoinFeeRate.toDouble() : null;
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return IntrinsicHeight(
                    // height: MediaQuery.of(context).size.height*0.4,
                    child: ModalNavigator(
                        parentContext: modalContext,
                        heightMode: ModalHeightModes.autoLock,
                        rootPage: Material(
                          child: NewPicker(
                              title: S.of(context).set_fees,
                              description: S.of(context).set_fees_desc,
                              sliderPageTitle: S.of(context).custom_fee,
                              sliderInitialValue: customFeeRate,
                              sliderMaxValue: maxCustomFeeRate,
                              sliderValueDescription: "sat/byte",
                              items: items
                                  .map((item) => PickerItem<TransactionPriority>(
                                title: item.title,
                                subtitle: item.description,
                                hint: item.hint,
                                value: item,
                                isSliderItem: items.indexOf(item) == customItemIndex,
                              ))
                                  .toList(),
                              onItemSelected: (TransactionPriority priority) async {
                                widget.sendViewModel.feesViewModel.setTransactionPriority(priority);
                                setState(() => selectedIdx = items.indexOf(priority));
                                await output.calculateEstimatedFee();
                              },
                              onSliderChanged: (double value) {
                                widget.sendViewModel.feesViewModel.customBitcoinFeeRate = value.round();
                              },
                              selectedIndex: selectedIdx),
                        )),
                  );
                },
              );
            }
        );
      },
    );
  }

  String _wrapAmount(String amount, int maxChars) {
    return amount.length <= maxChars ? amount : amount.substring(0, maxChars-3)+"...";
  }
}

class SendHelpPage extends StatelessWidget {
  const SendHelpPage({super.key, required this.content});

  final SendPageHelpContent content;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ModalTopBar(
            title: content.title,
            leadingIcon: Icon(Icons.arrow_back_ios_new),
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              spacing: 12,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(content.imagePath),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                if (content.disclaimer != null)
                 ...[SizedBox(),SizedBox(), Text(content.disclaimer!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),]
              ],
            ),
          ),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: NewPrimaryButton(
                  onPressed: Navigator.of(context).pop,
                  text: S.of(context).i_understand,
                  color: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.onPrimary))
        ],
      ),
    );
  }
}

