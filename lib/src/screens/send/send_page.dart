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
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_bottom_sheet.dart';
import 'package:cake_wallet/src/screens/send/widgets/send_card.dart';
import 'package:cake_wallet/src/widgets/add_template_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class SendPage extends BasePage {
  SendPage({
    required this.sendViewModel,
    required this.authService,
    this.initialPaymentRequest,
  }) : _formKey = GlobalKey<FormState>();

  final SendViewModel sendViewModel;
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
      color: titleColor(context),
      size: 16,
    );
    final _closeButton =
        currentTheme.type == ThemeType.dark ? closeButtonImageDarkTheme : closeButtonImage;

    bool isMobileView = responsiveLayoutUtil.shouldRenderMobileUI;

    return MergeSemantics(
      child: SizedBox(
        height: isMobileView ? 37 : 45,
        width: isMobileView ? 37 : 45,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: Semantics(
            label: !isMobileView ? S.of(context).close : S.of(context).seed_alert_back,
            child: TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith((states) => Colors.transparent),
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

  double _sendCardHeight(BuildContext context) {
    double initialHeight = 480;
    if (sendViewModel.hasCoinControl) {
      initialHeight += 55;
    }

    if (!responsiveLayoutUtil.shouldRenderMobileUI) {
      return initialHeight - 66;
    }
    return initialHeight;
  }

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
  Widget trailing(context) => Observer(builder: (_) {
        return sendViewModel.isBatchSending
            ? TrailButton(
                caption: S.of(context).remove,
                onPressed: () {
                  var pageToJump = (controller.page?.round() ?? 0) - 1;
                  pageToJump = pageToJump > 0 ? pageToJump : 0;
                  final output = _defineCurrentOutput();
                  sendViewModel.removeOutput(output);
                  controller.jumpToPage(pageToJump);
                })
            : TrailButton(
                caption: S.of(context).clear,
                onPressed: () {
                  final output = _defineCurrentOutput();
                  _formKey.currentState?.reset();
                  output.reset();
                });
      });

  bool _bottomSheetOpened = false;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return GestureDetector(
      onLongPress: () =>
          sendViewModel.balanceViewModel.isReversing = !sendViewModel.balanceViewModel.isReversing,
      onLongPressUp: () =>
          sendViewModel.balanceViewModel.isReversing = !sendViewModel.balanceViewModel.isReversing,
      child: Form(
        key: _formKey,
        child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: <Widget>[
                  Container(
                      height: _sendCardHeight(context),
                      child: Observer(
                        builder: (_) {
                          return PageView.builder(
                              scrollDirection: Axis.horizontal,
                              controller: controller,
                              itemCount: sendViewModel.outputs.length,
                              itemBuilder: (context, index) {
                                final output = sendViewModel.outputs[index];

                                return SendCard(
                                  key: output.key,
                                  output: output,
                                  sendViewModel: sendViewModel,
                                  initialPaymentRequest: initialPaymentRequest,
                                );
                              });
                        },
                      )),
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
                                            .extension<SendPageTheme>()!
                                            .indicatorDotColor,
                                        activeDotColor: Theme.of(context)
                                            .extension<SendPageTheme>()!
                                            .templateBackgroundColor),
                                  ))
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
                                onTap: () => Navigator.of(context).pushNamed(Routes.sendTemplate),
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
                                    hasMultipleRecipients: template.additionalRecipients != null &&
                                        template.additionalRecipients!.length > 1,
                                    amount: template.isCurrencySelected
                                        ? template.amount
                                        : template.amountFiat,
                                    from: template.isCurrencySelected
                                        ? template.cryptoCurrency
                                        : template.fiatCurrency,
                                    onTap: () async {
                                      sendViewModel.state = IsExecutingState();
                                      if (template.additionalRecipients?.isNotEmpty ?? false) {
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
                                              alertContent: S.of(context).confirm_delete_template,
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
                if (sendViewModel.hasCurrecyChanger)
                  Observer(
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: PrimaryButton(
                        key: ValueKey('send_page_change_asset_button_key'),
                        onPressed: () => presentCurrencyPicker(context),
                        text: 'Change your asset (${sendViewModel.selectedCryptoCurrency})',
                        color: Colors.transparent,
                        textColor: Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
                      ),
                    ),
                  ),
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
                        textColor: Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
                        isDottedBorder: true,
                        borderColor:
                            Theme.of(context).extension<SendPageTheme>()!.templateDottedBorderColor,
                      )),
                Observer(
                  builder: (_) {
                    return LoadingPrimaryButton(
                      key: ValueKey('send_page_send_button_key'),
                      onPressed: () async {
                        if (sendViewModel.state is IsExecutingState) return;
                        if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                          if (sendViewModel.outputs.length > 1) {
                            showErrorValidationAlert(context);
                          }

                          return;
                        }

                        final notValidItems = sendViewModel.outputs
                            .where((item) => item.address.isEmpty || item.cryptoAmount.isEmpty)
                            .toList();

                        if (notValidItems.isNotEmpty) {
                          showErrorValidationAlert(context);
                          return;
                        }

                        if (sendViewModel.wallet.isHardwareWallet) {
                          if (!sendViewModel.ledgerViewModel!.isConnected) {
                            await Navigator.of(context).pushNamed(
                                Routes.connectDevices,
                                arguments: ConnectDevicePageParams(
                                  walletType: sendViewModel.walletType,
                                  onConnectDevice: (BuildContext context, _) {
                                    sendViewModel.ledgerViewModel!
                                        .setLedger(sendViewModel.wallet);
                                    Navigator.of(context).pop();
                                  },
                                ));
                          } else {
                            sendViewModel.ledgerViewModel!
                                .setLedger(sendViewModel.wallet);
                          }
                        }

                        if (sendViewModel.wallet.type == WalletType.monero) {
                          int amount = 0;
                          for (var item in sendViewModel.outputs) {
                            amount += item.formattedCryptoAmount;
                          }
                          if (monero!.needExportOutputs(sendViewModel.wallet, amount)) {
                            await Navigator.of(context).pushNamed(Routes.urqrAnimatedPage, arguments: 'export-outputs');
                            await Future.delayed(Duration(seconds: 1)); // wait for monero to refresh the state
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
                      text: S.of(context).send,
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                      isLoading: sendViewModel.state is IsExecutingState ||
                          sendViewModel.state is TransactionCommitting ||
                          sendViewModel.state is IsAwaitingDeviceResponseState,
                      isDisabled: !sendViewModel.isReadyForSend,
                    );
                  },
                )
              ],
            )),
      ),
    );
  }

  BuildContext? dialogContext;

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    if (sendViewModel.isElectrumWallet) {
      bitcoin!.updateFeeRates(sendViewModel.wallet);
    }

    reaction((_) => sendViewModel.state, (ExecutionState state) {
      if (dialogContext != null && dialogContext?.mounted == true) {
        Navigator.of(dialogContext!).pop();
      }

      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    key: ValueKey('send_page_send_failure_dialog_key'),
                    buttonKey: ValueKey('send_page_send_failure_dialog_button_key'),
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }

      reaction((_) => sendViewModel.state, (ExecutionState state) {
        if (!_bottomSheetOpened &&
            (state is IsExecutingState ||
                state is TransactionCommitting ||
                state is IsAwaitingDeviceResponseState)) {
          _bottomSheetOpened = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              showModalBottomSheet<void>(
                context: context,
                isDismissible: false,
                isScrollControlled: true,
                builder: (BuildContext bottomSheetContext) {
                  return Observer(
                    builder: (_) {
                      if (sendViewModel.state is ExecutedSuccessfullyState) {
                        return ConfirmSendingBottomSheet(
                          key: ValueKey('send_page_confirm_sending_dialog_key'),
                          titleText: 'Confirm Transaction',
                          titleIconPath: sendViewModel.selectedCryptoCurrency.iconPath,
                          currency: sendViewModel.selectedCryptoCurrency,
                          amount: S.of(bottomSheetContext).send_amount,
                          amountValue: sendViewModel.pendingTransaction!.amountFormatted,
                          fiatAmountValue: sendViewModel.pendingTransactionFiatAmountFormatted,
                          fee: isEVMCompatibleChain(sendViewModel.walletType)
                              ? S.of(bottomSheetContext).send_estimated_fee
                              : S.of(bottomSheetContext).send_fee,
                          feeValue: sendViewModel.pendingTransaction!.feeFormatted,
                          feeFiatAmount: sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                          outputs: sendViewModel.outputs,
                          onSlideComplete: () async {
                            Navigator.of(bottomSheetContext).pop();
                            //sendViewModel.commitTransaction(context);

                            sendViewModel.state = TransactionCommitted();
                          },
                          change: sendViewModel.pendingTransaction!.change,
                        );
                      } else {
                        return ConfirmSendingBottomSheetPlaceholder();
                      }
                    },
                  );
                },
              ).whenComplete(() {
                _bottomSheetOpened = false;
              });
            }
          });
        }
      });

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          newContactAddress = newContactAddress ?? sendViewModel.newContactAddress();
          if (newContactAddress?.address != null &&
              isRegularElectrumAddress(newContactAddress!.address)) {
            newContactAddress = null;
          }

          if (sendViewModel.coinTypeToSpendFrom != UnspentCoinType.any) newContactAddress = null;

          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext bottomSheetContext) {
              return newContactAddress != null && sendViewModel.showAddressBookPopup
                  ? TransactionSuccessBottomSheet(
                      context: bottomSheetContext,
                      currentTheme: currentTheme,
                      showDontAskMeCheckbox: true,
                      onCheckboxChanged: (value) => sendViewModel.setShowAddressBookPopup(!value),
                      titleText: 'Transaction Sent',
                      contentImage: 'assets/images/contact_icon.svg',
                      contentImageColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                      content: S.of(bottomSheetContext).add_contact_to_address_book,
                      isTwoAction: true,
                      leftButtonText: 'No',
                      rightButtonText: 'Yes',
                      actionLeftButton: () {
                        Navigator.of(bottomSheetContext).pop();
                        RequestReviewHandler.requestReview();
                        newContactAddress = null;
                      },
                      actionRightButton: () {
                        Navigator.of(bottomSheetContext).pop();
                        RequestReviewHandler.requestReview();
                        Navigator.of(context)
                            .pushNamed(Routes.addressBookAddContact, arguments: newContactAddress);
                        newContactAddress = null;
                      },
                    )
                  : TransactionSuccessBottomSheet(
                      context: bottomSheetContext,
                      currentTheme: currentTheme,
                      titleText: 'Transaction Sent',
                      contentImage: 'assets/images/birthday_cake.svg',
                      actionButtonText: S.of(bottomSheetContext).close,
                      actionButtonKey: ValueKey('send_page_sent_dialog_ok_button_key'),
                      actionButton: () => Navigator.of(bottomSheetContext).pop());
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

      if (state is IsAwaitingDeviceResponseState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                dialogContext = context;
                return AlertWithOneAction(
                    alertTitle: S.of(context).proceed_on_device,
                    alertContent: S.of(context).proceed_on_device_description,
                    buttonText: S.of(context).cancel,
                    alertBarrierDismissible: false,
                    buttonAction: () {
                      sendViewModel.state = InitialExecutionState();
                      Navigator.of(context).pop();
                    });
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

  void presentCurrencyPicker(BuildContext context) async {
    await showPopUp<CryptoCurrency>(
        builder: (_) => Picker(
              items: sendViewModel.currencies,
              displayItem: (Object item) => item.toString(),
              selectedAtIndex:
                  sendViewModel.currencies.indexOf(sendViewModel.selectedCryptoCurrency),
              title: S.of(context).please_select,
              mainAxisAlignment: MainAxisAlignment.center,
              onItemSelected: (CryptoCurrency cur) => sendViewModel.selectedCryptoCurrency = cur,
            ),
        context: context);
  }

  bool isRegularElectrumAddress(String address) {
    final supportedTypes = [CryptoCurrency.btc, CryptoCurrency.ltc, CryptoCurrency.bch];
    final excludedPatterns = [
      RegExp(AddressValidator.silentPaymentAddressPattern),
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

}
