import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/contact_record.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/screens/send/widgets/send_card.dart';
import 'package:cake_wallet/src/widgets/adaptable_page_view.dart';
import 'package:cake_wallet/src/widgets/add_template_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/simple_checkbox.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/payment/payment_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cake_wallet/view_model/wallet_switcher_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobx/mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class SendPage extends BasePage {
  SendPage({
    required this.sendViewModel,
    required this.authService,
    required this.paymentViewModel,
    required this.walletSwitcherViewModel,
    this.initialPaymentRequest,
  }) : _formKey = GlobalKey<FormState>();

  final SendViewModel sendViewModel;
  final PaymentViewModel paymentViewModel;
  final WalletSwitcherViewModel walletSwitcherViewModel;
  final AuthService authService;
  final GlobalKey<FormState> _formKey;
  final controller = PageController(initialPage: 0);
  final PaymentRequest? initialPaymentRequest;

  bool _effectsInstalled = false;
  ContactRecord? newContactAddress;

  @override
  String get title => S.current.send;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  Function(BuildContext)? get pushToNextWidget => (context) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      };

  @override
  Widget? leading(BuildContext context) {
    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).colorScheme.primary,
      size: 16,
    );
    final _closeButton = currentTheme.isDark ? closeButtonImageDarkTheme : closeButtonImage;

    bool isMobileView = responsiveLayoutUtil.shouldRenderMobileUI;

    return MergeSemantics(
      child: SizedBox(
        height: isMobileView ? 37 : 45,
        width: isMobileView ? 47 : 45,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: !isMobileView ? S.of(context).close : S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent),
              ),
              onPressed: () => onClose(context),
              child: !isMobileView ? _closeButton : _backButton,
            ),
          ),
        ),
      ),
    );
  }

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  void onClose(BuildContext context) {
    sendViewModel.onClose();
    Navigator.of(context).pop();
  }

  @override
  Widget? middle(BuildContext context) {
    final supMiddle = super.middle(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Observer(
            builder: (_) => SyncIndicatorIcon(isSynced: sendViewModel.isReadyForSend),
          ),
        ),
        if (supMiddle != null) supMiddle
      ],
    );
  }

  @override
  Widget trailing(context) => Observer(
        builder: (_) {
          return sendViewModel.isBatchSending
              ? TrailButton(
                  caption: S.of(context).remove,
                  onPressed: () {
                    var pageToJump = (controller.page?.round() ?? 0) - 1;
                    pageToJump = pageToJump > 0 ? pageToJump : 0;
                    final output = _defineCurrentOutput();
                    sendViewModel.removeOutput(output);
                    controller.jumpToPage(pageToJump);
                  },
                )
              : TrailButton(
                  caption: S.of(context).clear,
                  onPressed: () {
                    final output = _defineCurrentOutput();
                    _formKey.currentState?.reset();
                    output.reset();
                  },
                );
        },
      );

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return Observer(builder: (_) {
      List<Widget> sendCards = [];
      List<KeyboardActionsItem> keyboardActions = [];
      for (var output in sendViewModel.outputs) {
        var cryptoAmountFocus = FocusNode();
        var fiatAmountFocus = FocusNode();
        sendCards.add(
          SendCard(
            currentTheme: currentTheme,
            key: output.key,
            output: output,
            sendViewModel: sendViewModel,
            paymentViewModel: paymentViewModel,
            walletSwitcherViewModel: walletSwitcherViewModel,
            initialPaymentRequest: initialPaymentRequest,
            cryptoAmountFocus: cryptoAmountFocus,
            fiatAmountFocus: fiatAmountFocus,
          ),
        );
        keyboardActions.add(
          KeyboardActionsItem(
            focusNode: cryptoAmountFocus,
            toolbarButtons: [(_) => KeyboardDoneButton()],
          ),
        );
        keyboardActions.add(
          KeyboardActionsItem(
            focusNode: fiatAmountFocus,
            toolbarButtons: [(_) => KeyboardDoneButton()],
          ),
        );
      }
      return Stack(
        children: [
          KeyboardActions(
            config: KeyboardActionsConfig(
              keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
              keyboardBarColor: Theme.of(context).colorScheme.surface,
              nextFocus: false,
              actions: keyboardActions,
            ),
            child: Container(
              height: 0,
              color: Colors.transparent,
            ),
          ),
          GestureDetector(
            onLongPress: () => sendViewModel.balanceViewModel.isReversing =
                !sendViewModel.balanceViewModel.isReversing,
            onLongPressUp: () => sendViewModel.balanceViewModel.isReversing =
                !sendViewModel.balanceViewModel.isReversing,
            child: Form(
              key: _formKey,
              child: ScrollableWithBottomSection(
                  contentPadding: EdgeInsets.only(bottom: 24),
                  content: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      children: <Widget>[
                        PageViewHeightAdaptable(
                          controller: controller,
                          children: sendCards,
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.only(left: 24, right: 24, bottom: 10),
                          child: Container(
                            height: 10,
                            child: Observer(
                              builder: (_) {
                                final count = sendViewModel.outputs.length;

                                return count > 1
                                    ? Semantics(
                                        label: 'Page Indicator',
                                        hint: 'Swipe to change receiver',
                                        excludeSemantics: true,
                                        child: SmoothPageIndicator(
                                          controller: controller,
                                          count: count,
                                          effect: ScrollingDotsEffect(
                                            spacing: 6.0,
                                            radius: 6.0,
                                            dotWidth: 6.0,
                                            dotHeight: 6.0,
                                            dotColor: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.4),
                                            activeDotColor: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      )
                                    : Offstage();
                              },
                            ),
                          ),
                        ),
                        Container(
                          height: 40,
                          width: double.infinity,
                          padding: EdgeInsets.only(left: 24),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Observer(
                              builder: (_) {
                                final templates = sendViewModel.templates;
                                final itemCount = templates.length;

                                return Row(
                                  children: <Widget>[
                                    AddTemplateButton(
                                      key: ValueKey('send_page_add_template_button_key'),
                                      onTap: () =>
                                          Navigator.of(context).pushNamed(Routes.sendTemplate),
                                      currentTemplatesLength: templates.length,
                                    ),
                                    ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: itemCount,
                                      itemBuilder: (context, index) {
                                        final template = templates[index];
                                        return TemplateTile(
                                          key: UniqueKey(),
                                          to: template.name,
                                          hasMultipleRecipients:
                                              template.additionalRecipients != null &&
                                                  template.additionalRecipients!.length > 1,
                                          amount: template.isCurrencySelected
                                              ? template.amount
                                              : template.amountFiat,
                                          from: template.isCurrencySelected
                                              ? template.cryptoCurrency
                                              : template.fiatCurrency,
                                          onTap: () async {
                                            sendViewModel.state = LoadingTemplateExecutingState();
                                            if (template.additionalRecipients?.isNotEmpty ??
                                                false) {
                                              sendViewModel.clearOutputs();

                                              for (int i = 0;
                                                  i < template.additionalRecipients!.length;
                                                  i++) {
                                                Output output;
                                                try {
                                                  output = sendViewModel.outputs[i];
                                                } catch (e) {
                                                  sendViewModel.addOutput();
                                                  output = sendViewModel.outputs[i];
                                                }

                                                await _setInputsFromTemplate(
                                                  context,
                                                  output: output,
                                                  template: template.additionalRecipients![i],
                                                );
                                              }
                                            } else {
                                              final output = _defineCurrentOutput();
                                              await _setInputsFromTemplate(
                                                context,
                                                output: output,
                                                template: template,
                                              );
                                            }
                                            sendViewModel.state = InitialExecutionState();
                                          },
                                          onRemove: () {
                                            showPopUp<void>(
                                              context: context,
                                              builder: (dialogContext) {
                                                return AlertWithTwoActions(
                                                    alertTitle: S.of(context).template,
                                                    alertContent:
                                                        S.of(context).confirm_delete_template,
                                                    rightButtonText: S.of(context).delete,
                                                    leftButtonText: S.of(context).cancel,
                                                    actionRightButton: () {
                                                      Navigator.of(dialogContext).pop();
                                                      sendViewModel.sendTemplateViewModel
                                                          .removeTemplate(template: template);
                                                    },
                                                    actionLeftButton: () =>
                                                        Navigator.of(dialogContext).pop());
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  bottomSection: Column(
                    children: [
                      if (sendViewModel.sendTemplateViewModel.hasMultiRecipient)
                        Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: PrimaryButton(
                              key: ValueKey('send_page_add_receiver_button_key'),
                              onPressed: () {
                                sendViewModel.addOutput();
                                Future.delayed(const Duration(milliseconds: 250), () {
                                  controller.jumpToPage(sendViewModel.outputs.length - 1);
                                });
                              },
                              text: S.of(context).add_receiver,
                              color: Colors.transparent,
                              textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                              isDottedBorder: true,
                              borderColor: Theme.of(context).colorScheme.outline,
                            )),
                      Observer(
                        builder: (_) {
                          return LoadingPrimaryButton(
                            key: ValueKey('send_page_send_button_key'),
                            onPressed: () async {
                              //Request dummy node to get the focus out of the text fields
                              FocusScope.of(context).requestFocus(FocusNode());

                              if (sendViewModel.state is IsExecutingState) return;
                              if (_formKey.currentState != null &&
                                  !_formKey.currentState!.validate()) {
                                if (sendViewModel.outputs.length > 1) {
                                  showErrorValidationAlert(context);
                                }

                                return;
                              }

                              final notValidItems = sendViewModel.outputs
                                  .where(
                                      (item) => item.address.isEmpty || item.cryptoAmount.isEmpty)
                                  .toList();

                              if (notValidItems.isNotEmpty) {
                                showErrorValidationAlert(context);
                                return;
                              }

                              if (sendViewModel.wallet.isHardwareWallet) {
                                if (!sendViewModel.hardwareWalletViewModel!.isConnected) {
                                  await Navigator.of(context).pushNamed(Routes.connectDevices,
                                      arguments: ConnectDevicePageParams(
                                        walletType: sendViewModel.walletType,
                                        hardwareWalletType:
                                            sendViewModel.wallet.walletInfo.hardwareWalletType!,
                                        onConnectDevice: (BuildContext context, _) {
                                          sendViewModel.hardwareWalletViewModel!
                                              .initWallet(sendViewModel.wallet);
                                          Navigator.of(context).pop();
                                        },
                                      ));
                                } else {
                                  sendViewModel.hardwareWalletViewModel!
                                      .initWallet(sendViewModel.wallet);
                                }
                              }

                              if (sendViewModel.wallet.type == WalletType.monero) {
                                int amount = 0;
                                for (var item in sendViewModel.outputs) {
                                  amount += item.formattedCryptoAmount;
                                }
                                if (monero!.needExportOutputs(sendViewModel.wallet, amount)) {
                                  await Navigator.of(context).pushNamed(Routes.urqrAnimatedPage,
                                      arguments: monero!.exportOutputsUR(sendViewModel.wallet));
                                  await Future.delayed(
                                      Duration(seconds: 1)); // wait for monero to refresh the state
                                }
                                if (monero!.needExportOutputs(sendViewModel.wallet, amount)) {
                                  return;
                                }
                              }

                              final check = sendViewModel.shouldDisplayTotp();
                              authService.authenticateAction(
                                context,
                                conditionToDetermineIfToUse2FA: check,
                                onAuthSuccess: (value) async {
                                  if (value) {
                                    await sendViewModel.createTransaction();
                                  }
                                },
                              );
                            },
                            text: _sendButtonText(context),
                            color: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            isLoading: sendViewModel.state is IsExecutingState ||
                                sendViewModel.state is TransactionCommitting ||
                                sendViewModel.state is IsAwaitingDeviceResponseState ||
                                sendViewModel.state is LoadingTemplateExecutingState,
                            isDisabled: !sendViewModel.isReadyForSend || sendViewModel.state is ExecutedSuccessfullyState,
                          );
                        },
                      )
                    ],
                  )),
            ),
          ),
        ],
      );
    });
  }

  BuildContext? dialogContext;
  BuildContext? loadingBottomSheetContext;

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    if (sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(sendViewModel.wallet);
    }

    reaction((_) => sendViewModel.state, (ExecutionState state) async {
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
              builder: (BuildContext context) {
                return AlertWithOneAction(
                  key: ValueKey('send_page_send_failure_dialog_key'),
                  buttonKey: ValueKey('send_page_send_failure_dialog_button_key'),
                  alertTitle: S.of(context).error,
                  alertContent: state.error,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop(),
                );
              },
            );
          },
        );
      }

      if (state is IsExecutingState) {
        // wait a bit to avoid showing the loading dialog if transaction is failed
        await Future.delayed(const Duration(milliseconds: 300));
        final currentState = sendViewModel.state;
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
                    accessibleNavigationModeSlideActionButtonText:
                        S.of(bottomSheetContext).send,
                    footerType: FooterType.slideActionButton,
                    isSlideActionEnabled: sendViewModel.isReadyForSend,
                    walletType: sendViewModel.walletType,
                    titleIconPath: sendViewModel.selectedCryptoCurrency.iconPath,
                    currency: sendViewModel.selectedCryptoCurrency,
                    amount: S.of(bottomSheetContext).send_amount,
                    amountValue: sendViewModel.pendingTransaction!.amountFormatted,
                    fiatAmountValue: sendViewModel.pendingTransactionFiatAmountFormatted,
                    fee: isEVMCompatibleChain(sendViewModel.walletType)
                        ? S.of(bottomSheetContext).send_estimated_fee
                        : S.of(bottomSheetContext).send_fee,
                    feeValue: sendViewModel.pendingTransaction!.feeFormatted,
                    feeFiatAmount:
                        sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                    outputs: sendViewModel.outputs,
                    onSlideActionComplete: () async {
                      Navigator.of(bottomSheetContext).pop(true);
                      sendViewModel.commitTransaction(context);
                    },
                    change: sendViewModel.pendingTransaction!.change,
                    isOpenCryptoPay: sendViewModel.ocpRequest != null,
                  ),
                );
              },
            );

            if (result == null) sendViewModel.dismissTransaction();
          }
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) {
            return;
          }

          newContactAddress = newContactAddress ?? sendViewModel.newContactAddress();

          if (newContactAddress?.address != null &&
              isRegularElectrumAddress(newContactAddress!.address)) {
            newContactAddress = null;
          }

          bool showContactSheet = (newContactAddress != null && sendViewModel.showAddressBookPopup);

          await showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (BuildContext bottomSheetContext) {
              return showContactSheet && sendViewModel.ocpRequest == null
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
                                    sendViewModel.setShowAddressBookPopup(!value)),
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

          if (initialPaymentRequest?.callbackUrl?.isNotEmpty ?? false) {
            // wait a second so it's not as jarring:
            await Future.delayed(Duration(seconds: 1));
            try {
              launchUrl(
                Uri.parse(initialPaymentRequest!.callbackUrl!),
                mode: LaunchMode.externalApplication,
              );
            } catch (e) {
              printV(e);
            }
          }

          sendViewModel.clearOutputs();
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
                    sendViewModel.state = InitialExecutionState();
                    Navigator.of(context).pop();
                  },
                );
              });
        });
      }
    });

    _effectsInstalled = true;
  }

  Future<void> _setInputsFromTemplate(BuildContext context,
      {required Output output, required Template template}) async {
    output.address = template.address;

    if (template.isCurrencySelected) {
      sendViewModel.setSelectedCryptoCurrency(template.cryptoCurrency);
      output.setCryptoAmount(template.amount);
    } else {
      final fiatFromTemplate =
          FiatCurrency.all.singleWhere((element) => element.title == template.fiatCurrency);

      sendViewModel.setFiatCurrency(fiatFromTemplate);
      output.setFiatAmount(template.amountFiat);
    }

    output.resetParsedAddress();
    await output.fetchParsedAddress(context);
  }

  Output _defineCurrentOutput() {
    if (controller.page == null) {
      throw Exception('Controller page is null');
    }
    final itemCount = controller.page!.round();
    return sendViewModel.outputs[itemCount];
  }

  void showErrorValidationAlert(BuildContext context) async {
    await showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.of(context).error,
              alertContent: 'Please, check receiver forms',
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  bool isRegularElectrumAddress(String address) {
    final supportedTypes = [CryptoCurrency.btc, CryptoCurrency.ltc, CryptoCurrency.bch];
    final excludedPatterns = [
      RegExp(AddressValidator.silentPaymentAddressPatternMainnet),
      RegExp(AddressValidator.silentPaymentAddressPatternTestnet),
      RegExp(AddressValidator.mWebAddressPattern)
    ];

    final trimmed = address.trim();

    bool isValid = false;
    for (var type in supportedTypes) {
      final addressPattern = AddressValidator.getAddressFromStringPattern(type);
      if (addressPattern != null) {
        final regex = RegExp('^$addressPattern\$');
        if (regex.hasMatch(trimmed)) {
          isValid = true;
          break;
        }
      }
    }

    for (var pattern in excludedPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return false;
      }
    }

    return isValid;
  }

  String _sendButtonText(BuildContext context) {
    if (!sendViewModel.isReadyForSend) {
      return S.of(context).synchronizing;
    }
    if (sendViewModel.payjoinUri != null) {
      return S.of(context).send_payjoin;
    } else {
      return S.of(context).send;
    }
  }
}
