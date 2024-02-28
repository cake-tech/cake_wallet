import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/screens/send/widgets/send_card.dart';
import 'package:cake_wallet/src/widgets/add_template_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cw_core/crypto_currency.dart';

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

  @override
  String get title => S.current.send;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

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
    final double initialHeight = sendViewModel.hasCoinControl ? 500 : 465;

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
                    padding: EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 10),
                    child: Container(
                      height: 10,
                      child: Observer(
                        builder: (_) {
                          final count = sendViewModel.outputs.length;

                          return count > 1
                              ? SmoothPageIndicator(
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
                            onPressed: () => presentCurrencyPicker(context),
                            text: 'Change your asset (${sendViewModel.selectedCryptoCurrency})',
                            color: Colors.transparent,
                            textColor:
                                Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
                          ))),
                if (sendViewModel.sendTemplateViewModel.hasMultiRecipient)
                  Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: PrimaryButton(
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
                      onPressed: () async {
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
                          sendViewModel.state is TransactionCommitting,
                      isDisabled: !sendViewModel.isReadyForSend,
                    );
                  },
                )
              ],
            )),
      ),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    reaction((_) => sendViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showPopUp<void>(
                context: context,
                builder: (BuildContext _dialogContext) {
                  return ConfirmSendingAlert(
                      alertTitle: S.of(_dialogContext).confirm_sending,
                      amount: S.of(_dialogContext).send_amount,
                      amountValue: sendViewModel.pendingTransaction!.amountFormatted,
                      fiatAmountValue: sendViewModel.pendingTransactionFiatAmountFormatted,
                      fee: isEVMCompatibleChain(sendViewModel.walletType)
                          ? S.of(_dialogContext).send_estimated_fee
                          : S.of(_dialogContext).send_fee,
                      feeValue: sendViewModel.pendingTransaction!.feeFormatted,
                      feeFiatAmount: sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                      outputs: sendViewModel.outputs,
                      rightButtonText: S.of(_dialogContext).send,
                      leftButtonText: S.of(_dialogContext).cancel,
                      actionRightButton: () {
                        Navigator.of(_dialogContext).pop();
                        sendViewModel.commitTransaction();
                        showPopUp<void>(
                            context: context,
                            builder: (BuildContext _dialogContext) {
                              return Observer(builder: (_) {
                                final state = sendViewModel.state;

                                if (state is FailureState) {
                                  Navigator.of(_dialogContext).pop();
                                }

                                if (state is TransactionCommitted) {
                                  String alertContent;
                                  if (sendViewModel.walletType == WalletType.solana) {
                                    alertContent =
                                        '${S.of(_dialogContext).send_success(sendViewModel.selectedCryptoCurrency.toString())}. ${S.of(_dialogContext).waitFewSecondForTxUpdate}';
                                  } else {
                                    alertContent = S.of(_dialogContext).send_success(
                                        sendViewModel.selectedCryptoCurrency.toString());
                                  }
                                  return AlertWithOneAction(
                                      alertTitle: '',
                                      alertContent: alertContent,
                                      buttonText: S.of(_dialogContext).ok,
                                      buttonAction: () {
                                        Navigator.of(_dialogContext).pop();
                                        RequestReviewHandler.requestReview();
                                      });
                                }

                                return Offstage();
                              });
                            });
                      },
                      actionLeftButton: () => Navigator.of(_dialogContext).pop());
                });
          }
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sendViewModel.clearOutputs();
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
}
