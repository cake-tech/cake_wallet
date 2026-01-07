import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/open_crypto_pay/open_cryptopay_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_dropdown.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import "package:cw_core/wallet_type.dart";
import 'package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/recipient_dot_row.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_amount_input.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/send_syncing_indicator.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart' show Routes;
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/evm_payment_flow_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/payment_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/swap_confirmation_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/wallet_switcher_bottom_sheet.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/simple_checkbox.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

class NewSendPage extends StatefulWidget {
  const NewSendPage(
      {super.key,
      required this.sendViewModel,
      required this.paymentViewModel,
      required this.walletSwitcherViewModel,
      required this.authService,
      this.initialPaymentRequest});

  final SendViewModel sendViewModel;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final AuthService authService;
  final PaymentRequest? initialPaymentRequest;

  @override
  State<NewSendPage> createState() => _NewSendPageState();
}

class _NewSendPageState extends State<NewSendPage> {
  bool _advancedOptionsExpanded = false;
  bool _fiatInputMode = false;
  int _selectedOutput = 0;

  // final TextEditingController _amountController = TextEditingController();
  // final TextEditingController _addressController = TextEditingController();

  List<TextEditingController> _amountControllers = [];
  List<TextEditingController> _addressControllers = [];
  BuildContext? loadingBottomSheetContext;
  BuildContext? dialogContext;
  ContactRecord? newContactAddress;

  @override
  void initState() {
    super.initState();
    _addInputControllers();

    reaction((_) => widget.sendViewModel.state, (ExecutionState state) async {
      if (dialogContext != null && dialogContext?.mounted == true) {
        Navigator.of(dialogContext!).pop();
      }

      if (state is! IsExecutingState &&
          loadingBottomSheetContext != null &&
          loadingBottomSheetContext!.mounted) {
        Navigator.of(loadingBottomSheetContext!).pop();
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            showPopUp<void>(
              context: context,
              builder: (context) => AlertWithOneAction(
                key: ValueKey('send_page_send_failure_dialog_key'),
                buttonKey: ValueKey('send_page_send_failure_dialog_button_key'),
                alertTitle: S.of(context).error,
                alertContent: state.error,
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop(),
              ),
            );
          },
        );
      }

      if (state is IsExecutingState) {
        // wait a bit to avoid showing the loading dialog if transaction is failed
        await Future.delayed(const Duration(milliseconds: 300));
        final currentState = widget.sendViewModel.state;
        if (currentState is ExecutedSuccessfullyState || currentState is FailureState) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (context) {
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
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (context.mounted) {
            final result = await showModalBottomSheet<bool>(
              context: context,
              isDismissible: false,
              isScrollControlled: true,
              builder: (BuildContext bottomSheetContext) {
                return Observer(
                  builder: (_) => ConfirmSendingBottomSheet(
                    key: ValueKey('send_page_confirm_sending_bottom_sheet_key'),
                    titleText: S.of(bottomSheetContext).confirm_transaction,
                    accessibleNavigationModeSlideActionButtonText: S.of(bottomSheetContext).send,
                    footerType: FooterType.slideActionButton,
                    isSlideActionEnabled: widget.sendViewModel.isReadyForSend,
                    walletType: widget.sendViewModel.walletType,
                    titleIconPath: widget.sendViewModel.selectedCryptoCurrency.iconPath,
                    currency: widget.sendViewModel.selectedCryptoCurrency,
                    amount: S.of(bottomSheetContext).send_amount,
                    amountValue: widget.sendViewModel.pendingTransaction!.amountFormatted,
                    fiatAmountValue: widget.sendViewModel.pendingTransactionFiatAmountFormatted,
                    fee: isEVMCompatibleChain(widget.sendViewModel.walletType)
                        ? S.of(bottomSheetContext).send_estimated_fee
                        : S.of(bottomSheetContext).send_fee,
                    feeValue: widget.sendViewModel.pendingTransaction!.feeFormatted,
                    feeFiatAmount: widget.sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                    outputs: widget.sendViewModel.outputs,
                    onSlideActionComplete: () async {
                      Navigator.of(bottomSheetContext).pop(true);
                      widget.sendViewModel.commitTransaction(context);
                    },
                    change: widget.sendViewModel.pendingTransaction!.change,
                    isOpenCryptoPay: widget.sendViewModel.ocpRequest != null,
                  ),
                );
              },
            );

            if (result == null) widget.sendViewModel.dismissTransaction();
          }
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          newContactAddress = newContactAddress ?? widget.sendViewModel.newContactAddress();

          if (newContactAddress?.address != null &&
              isRegularElectrumAddress(newContactAddress!.address)) {
            newContactAddress = null;
          }

          bool showContactSheet =
              (newContactAddress != null && widget.sendViewModel.showAddressBookPopup);

          await showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (BuildContext bottomSheetContext) {
              return showContactSheet && widget.sendViewModel.ocpRequest == null
                  ? InfoBottomSheet(
                      footerType: FooterType.doubleActionButton,
                      titleText: S.of(bottomSheetContext).transaction_sent,
                      contentImage: 'assets/images/contact.png',
                      contentImageColor: Theme.of(context).colorScheme.onSurface,
                      content: S.of(bottomSheetContext).add_contact_to_address_book,
                      leftActionButtonKey:
                          ValueKey('send_page_add_contact_bottom_sheet_no_button_key'),
                      rightActionButtonKey:
                          ValueKey('send_page_add_contact_bottom_sheet_yes_button_key'),
                      bottomActionPanel: Padding(
                        padding: const EdgeInsets.only(left: 34.0),
                        child: Row(
                          children: [
                            SimpleCheckbox(
                                onChanged: (value) =>
                                    widget.sendViewModel.setShowAddressBookPopup(!value)),
                            const SizedBox(width: 8),
                            Text(
                              'Don’t ask me next time',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).textTheme.titleLarge!.color,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      doubleActionLeftButtonText: 'No',
                      doubleActionRightButtonText: 'Yes',
                      onLeftActionButtonPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
                        }
                        RequestReviewHandler.requestReview();
                        newContactAddress = null;
                      },
                      onRightActionButtonPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        RequestReviewHandler.requestReview();
                        if (context.mounted) {
                          Navigator.of(context).pushNamed(Routes.addressBookAddContact,
                              arguments: newContactAddress);
                        }
                        newContactAddress = null;
                      },
                    )
                  : InfoBottomSheet(
                      footerType: FooterType.singleActionButton,
                      titleText: S.of(bottomSheetContext).transaction_sent,
                      contentImage: 'assets/images/birthday_cake.png',
                      singleActionButtonText: S.of(bottomSheetContext).close,
                      singleActionButtonKey: ValueKey('send_page_transaction_sent_button_key'),
                      onSingleActionButtonPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        Future.delayed(Duration.zero, () {
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
                          }
                          RequestReviewHandler.requestReview();
                          newContactAddress = null;
                        });
                      },
                    );
            },
          );

          if (widget.initialPaymentRequest?.callbackUrl?.isNotEmpty ?? false) {
            // wait a second so it's not as jarring:
            await Future.delayed(Duration(seconds: 1));
            try {
              launchUrl(
                Uri.parse(widget.initialPaymentRequest!.callbackUrl!),
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              printV(e);
            }
          }

          widget.sendViewModel.clearOutputs();
        });
      }

      if (state is IsDeviceSigningResponseState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (context) {
              dialogContext = context;
              return LoadingBottomSheet(titleText: S.of(context).processing_signed_tx);
            },
          );
        });
      }

      if (state is IsAwaitingDeviceResponseState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;

          showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              builder: (context) {
                dialogContext = context;
                return InfoBottomSheet(
                  footerType: FooterType.singleActionButton,
                  titleText: S.of(context).proceed_on_device,
                  contentImage: 'assets/images/hardware_wallet/ledger_nano_x.png',
                  contentImageColor: Theme.of(context).colorScheme.onSurface,
                  content: S.of(context).proceed_on_device_description,
                  singleActionButtonText: S.of(context).cancel,
                  onSingleActionButtonPressed: () {
                    widget.sendViewModel.state = InitialExecutionState();
                    Navigator.of(context).pop();
                  },
                );
              });
        });
      }
    });

    reaction((_) => widget.sendViewModel.outputs[_selectedOutput].sendAll, ((bool all) {
      if (all) {
        _fiatInputMode = false;
        _amountControllers[_selectedOutput].text = S.current.all;
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final output = widget.sendViewModel.outputs[_selectedOutput];

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: SafeArea(
          child: Column(
            spacing: 12,
            mainAxisSize: MainAxisSize.max,
            children: [
              ModalTopBar(
                  title: "Send",
                  leadingIcon: Icon(Icons.close),
                  onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                trailingWidget: Observer(
                  builder:(_)=> Row(
                    spacing: 8,
                    children: [
                      if (widget.sendViewModel.outputs.length > 1)
                        ModernButton(
                            size: 36,
                            icon: Icon(Icons.delete_forever_outlined),
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
                      ModernButton(
                          size: 36,
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _addInputControllers();
                            widget.sendViewModel.addOutput();
                            _setOutput(widget.sendViewModel.outputs.length - 1);
                          })
                    ],
                  ),
                ),
              ),
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
                          spacing: 12,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Address or alias"),
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
                              onPushAddressBookButton: (context) async {
                                output.resetParsedAddress();
                              },
                              onSelectedContact: (contact) {
                                output.loadContact(contact);
                              },
                              selectedCurrency: widget.sendViewModel.selectedCryptoCurrency,
                            ),
                            Text("Amount"),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    ModernButton.svg(
                                        size: 28,
                                        svgPath: "assets/new-ui/switch.svg",
                                        iconSize: 18,
                                        onPressed: () {
                                          setState(() {
                                            _fiatInputMode = !_fiatInputMode;
                                            _amountControllers[_selectedOutput].text = _fiatInputMode
                                                ? output.fiatAmount
                                                : output.cryptoAmount;
                                          });
                                        }),
                                    Observer(
                                        builder: (_) => Text( _fiatInputMode
                                            ? "${output.cryptoAmount.isEmpty ? "0" : output.cryptoAmount} ${widget.sendViewModel.selectedCryptoCurrency.title}"
                                            : "${output.cryptoAmount.isEmpty ? "0" : output.fiatAmount} ${widget.sendViewModel.fiatCurrency.title}",)),
                                  ],
                                ),
                                Row(
                                  spacing: 8,
                                  children: [
                                    Text("Available"),
                                    Material(
                                        color: Theme.of(context).colorScheme.surfaceContainer,
                                        borderRadius: BorderRadius.circular(99999),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(99999),
                                          onTap: () async {
                                            output.setSendAll(
                                                await widget.sendViewModel.sendingBalance);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0, vertical: 4),
                                            child: Text(
                                              widget.sendViewModel.balance,
                                              style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary),
                                            ),
                                          ),
                                        ))
                                  ],
                                )
                              ],
                            ),
                            NewListSections(sections: {
                              "": [
                                ListItemDropdown(
                                  keyValue: "",
                                  label: "Advanced Settings",
                                  onTap: () {
                                    setState(() {
                                      _advancedOptionsExpanded = !_advancedOptionsExpanded;
                                    });
                                  },
                                ),
                                if (_advancedOptionsExpanded && widget.sendViewModel.hasFees)
                                  ListItemRegularRow(
                                    keyValue: "",
                                    label: "Fees",
                                    subtitle: "~${output.estimatedFee} ${widget.sendViewModel.currency} (${output.estimatedFeeFiatAmount} ${widget.sendViewModel.fiatCurrency})",

                                    onTap: () {
                                      if (widget.sendViewModel.feesViewModel.hasFeesPriority)
                                        pickTransactionPriority(context, output);
                                    },
                                  ),
                                if (_advancedOptionsExpanded)
                                  ListItemRegularRow(
                                    keyValue: "",
                                    label: "Coin Control",
                                    onTap: () {
                                      Navigator.of(context).pushNamed(Routes.unspentCoinsList);
                                    },
                                  )
                              ]
                            })
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
                                    //TODO refactor this action. code was copied over from old ui. i don't like it.
                                    //Request dummy node to get the focus out of the text fields
                                    FocusScope.of(context).requestFocus(FocusNode());

                                    if (widget.sendViewModel.state is IsExecutingState) return;
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
                                      context,
                                      conditionToDetermineIfToUse2FA: check,
                                      onAuthSuccess: (value) async {
                                        if (value) {
                                          await widget.sendViewModel.createTransaction();
                                        }
                                      },
                                    );
                                  },
                                  text: "Continue",
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
                            )
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

        if (amount != output.cryptoAmount) {
          output.setCryptoAmount(amount);
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
            selectedCurrency = widget.sendViewModel.fiatCurrency = (cur as FiatCurrency);
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
          await _showEVMPaymentFlow(
            widget.paymentViewModel,
            widget.walletSwitcherViewModel,
            paymentRequest,
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

  void _applyPaymentRequest(PaymentRequest paymentRequest) {
    if (widget.sendViewModel.usePayjoin) {
      widget.sendViewModel.payjoinUri = paymentRequest.pjUri;
    }
    _addressControllers[_selectedOutput].text = paymentRequest.address;
    if (paymentRequest.amount.isNotEmpty) {
      _fiatInputMode = false;
      _amountControllers[_selectedOutput].text = paymentRequest.amount;
    }
    // noteController.text = paymentRequest.note;
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
          onSwap: () => _handleSwapFlow(paymentViewModel, result),
        );
      },
    );
  }

  Future<void> _showEVMPaymentFlow(
    PaymentViewModel paymentViewModel,
    WalletSwitcherViewModel walletSwitcherViewModel,
    PaymentRequest paymentRequest,
  ) async {
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return EVMPaymentFlowBottomSheet(
          paymentViewModel: paymentViewModel,
          paymentRequest: paymentRequest,
          onNext: (PaymentFlowResult newResult) {
            if (newResult.addressDetectionResult!.detectedWalletType ==
                paymentViewModel.currentWalletType) {
              widget.sendViewModel.setSelectedCryptoCurrency(
                  newResult.addressDetectionResult!.detectedCurrency!.title);
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

  Future<void> _handleSwapFlow(PaymentViewModel paymentViewModel, PaymentFlowResult result) async {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    final bottomSheet = getIt.get<SwapConfirmationBottomSheet>(param1: result);
    await showModalBottomSheet<Trade?>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) => bottomSheet,
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
      await widget.sendViewModel.wallet.updateBalance();
      widget.sendViewModel
          .setSelectedCryptoCurrency(result.addressDetectionResult!.detectedCurrency!.title);
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

        await widget.sendViewModel.wallet.updateBalance();
        widget.sendViewModel
            .setSelectedCryptoCurrency(result.addressDetectionResult!.detectedCurrency!.title);
        _applyPaymentRequest(paymentRequest);
      }
    }
  }

  void showErrorValidationAlert(BuildContext context) => showPopUp<void>(
        context: context,
        builder: (context) => AlertWithOneAction(
          alertTitle: S.of(context).error,
          alertContent: 'Please, check receiver forms',
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        ),
      );

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

  Future<void> pickTransactionPriority(BuildContext context, Output output) async {
    final items = priorityForWalletType(widget.sendViewModel.walletType);
    final selectedItem = items.indexOf(widget.sendViewModel.feesViewModel.transactionPriority);
    final customItemIndex = widget.sendViewModel.feesViewModel.getCustomPriorityIndex(items);
    final isBitcoinWallet = widget.sendViewModel.walletType == WalletType.bitcoin;
    final maxCustomFeeRate = widget.sendViewModel.feesViewModel.maxCustomFeeRate?.toDouble();
    double? customFeeRate =
        isBitcoinWallet ? widget.sendViewModel.feesViewModel.customBitcoinFeeRate.toDouble() : null;

    FocusManager.instance.primaryFocus?.unfocus();

    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        int selectedIdx = selectedItem;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Picker(
              items: items,
              displayItem: (TransactionPriority priority) => widget.sendViewModel.feesViewModel
                  .displayFeeRate(priority, customFeeRate?.round()),
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
                widget.sendViewModel.feesViewModel.setTransactionPriority(priority);
                setState(() => selectedIdx = items.indexOf(priority));
                await output.calculateEstimatedFee();
              },
            );
          },
        );
      },
    );
    if (isBitcoinWallet)
      widget.sendViewModel.feesViewModel.customBitcoinFeeRate = customFeeRate!.round();
  }
}
