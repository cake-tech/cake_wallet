import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/template.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';
import 'package:cake_wallet/src/screens/send/widgets/send_card.dart';
import 'package:cake_wallet/src/widgets/add_template_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/template_tile.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
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

class LightningSendConfirmPage extends BasePage {
  LightningSendConfirmPage({this.invoice}) : _formKey = GlobalKey<FormState>();

  final GlobalKey<FormState> _formKey;
  final controller = PageController(initialPage: 0);
  LNInvoice? invoice;

  final bolt11Controller = TextEditingController();
  final _bolt11FocusNode = FocusNode();

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
    final double initialHeight = 465;

    if (!responsiveLayoutUtil.shouldRenderMobileUI) {
      return initialHeight - 66;
    }
    return initialHeight;
  }

  @override
  void onClose(BuildContext context) {
    // sendViewModel.onClose();
    Navigator.of(context).pop();
  }

  // @override
  // Widget? middle(BuildContext context) {
  //   final supMiddle = super.middle(context);
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(right: 8.0),
  //         child: Observer(
  //           builder: (_) => SyncIndicatorIcon(isSynced: sendViewModel.isReadyForSend),
  //         ),
  //       ),
  //       if (supMiddle != null) supMiddle
  //     ],
  //   );
  // }

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return WillPopScope(
      onWillPop: () => _onNavigateBack(context),
      child: KeyboardActions(
        disableScroll: true,
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor: Theme.of(context).extension<KeyboardTheme>()!.keyboardBarColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: FocusNode(),
                // focusNode: _amountFocusNode,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              ),
            ]),
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Container(
              decoration: responsiveLayoutUtil.shouldRenderMobileUI
                  ? BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .firstGradientTopPanelColor,
                          Theme.of(context)
                              .extension<ExchangePageTheme>()!
                              .secondGradientTopPanelColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: Observer(builder: (_) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(24, 120, 24, 0),
                  child: BaseTextFormField(
                    controller: bolt11Controller,
                    focusNode: _bolt11FocusNode,
                    textInputAction: TextInputAction.next,
                    borderColor: Theme.of(context)
                        .extension<ExchangePageTheme>()!
                        .textFieldBorderTopPanelColor,
                    suffixIcon: SizedBox(width: 36),
                    hintText: S.of(context).invoice_details,
                    placeholderTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                    ),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    validator: null,
                  ),
                );
              }),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Observer(builder: (_) {
              return Column(
                children: <Widget>[
                  // Padding(
                  //   padding: EdgeInsets.only(bottom: 15),
                  //   child: Center(
                  //     child: Text(
                  //       S.of(context).anonpay_description("an invoice", "pay"),
                  //       textAlign: TextAlign.center,
                  //       style: TextStyle(
                  //           color: Theme.of(context)
                  //               .extension<ExchangePageTheme>()!
                  //               .receiveAmountColor,
                  //           fontWeight: FontWeight.w500,
                  //           fontSize: 12),
                  //     ),
                  //   ),
                  // ),
                  LoadingPrimaryButton(
                    text: S.of(context).send,
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      // sendViewModel.send(bolt11Controller.text);
                      final sdk = await BreezSDK();
                    },
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                    isLoading: false,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<bool> _onNavigateBack(BuildContext context) async {
    onClose(context);
    return false;
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    // reaction((_) => sendViewModel.state, (ExecutionState state) {
    //   if (state is FailureState) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       showPopUp<void>(
    //           context: context,
    //           builder: (BuildContext context) {
    //             return AlertWithOneAction(
    //                 alertTitle: S.of(context).error,
    //                 alertContent: state.error,
    //                 buttonText: S.of(context).ok,
    //                 buttonAction: () => Navigator.of(context).pop());
    //           });
    //     });
    //   }

    //   if (state is ExecutedSuccessfullyState) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       if (context.mounted) {
    //         showPopUp<void>(
    //             context: context,
    //             builder: (BuildContext _dialogContext) {
    //               return ConfirmSendingAlert(
    //                   alertTitle: S.of(_dialogContext).confirm_sending,
    //                   amount: S.of(_dialogContext).send_amount,
    //                   amountValue: sendViewModel.pendingTransaction!.amountFormatted,
    //                   fiatAmountValue: sendViewModel.pendingTransactionFiatAmountFormatted,
    //                   fee: S.of(_dialogContext).send_fee,
    //                   feeValue: sendViewModel.pendingTransaction!.feeFormatted,
    //                   feeFiatAmount: sendViewModel.pendingTransactionFeeFiatAmountFormatted,
    //                   outputs: sendViewModel.outputs,
    //                   rightButtonText: S.of(_dialogContext).send,
    //                   leftButtonText: S.of(_dialogContext).cancel,
    //                   actionRightButton: () {
    //                     Navigator.of(_dialogContext).pop();
    //                     sendViewModel.commitTransaction();
    //                     showPopUp<void>(
    //                         context: context,
    //                         builder: (BuildContext _dialogContext) {
    //                           return Observer(builder: (_) {
    //                             final state = sendViewModel.state;

    //                             if (state is FailureState) {
    //                               Navigator.of(_dialogContext).pop();
    //                             }

    //                             if (state is TransactionCommitted) {
    //                               return AlertWithOneAction(
    //                                   alertTitle: '',
    //                                   alertContent: S.of(_dialogContext).send_success(
    //                                       sendViewModel.selectedCryptoCurrency.toString()),
    //                                   buttonText: S.of(_dialogContext).ok,
    //                                   buttonAction: () {
    //                                     Navigator.of(_dialogContext).pop();
    //                                     RequestReviewHandler.requestReview();
    //                                   });
    //                             }

    //                             return Offstage();
    //                           });
    //                         });
    //                   },
    //                   actionLeftButton: () => Navigator.of(_dialogContext).pop());
    //             });
    //       }
    //     });
    //   }

    //   if (state is TransactionCommitted) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       sendViewModel.clearOutputs();
    //     });
    //   }
    // });

    _effectsInstalled = true;
  }
}
