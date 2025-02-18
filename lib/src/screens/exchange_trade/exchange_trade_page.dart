import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/desktop_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/mobile_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/exchange_trade_card_item_widget.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'dart:ui';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_alert.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/timer_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

void showInformation(
    ExchangeTradeViewModel exchangeTradeViewModel, BuildContext context) {
  final trade = exchangeTradeViewModel.trade;
  final walletName = exchangeTradeViewModel.wallet.name;

  final information = exchangeTradeViewModel.isSendable
      ? S.current.exchange_result_confirm(
          trade.amount, trade.from.toString(), walletName) +
        exchangeTradeViewModel.extraInfo
      : S.current.exchange_result_description(
          trade.amount, trade.from.toString()) +
        exchangeTradeViewModel.extraInfo;

  showPopUp<void>(
      context: context,
      builder: (_) => InformationPage(
        key: ValueKey('information_page_dialog_key'),
        information: information));
}

class ExchangeTradePage extends BasePage {
  ExchangeTradePage({required this.exchangeTradeViewModel});

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  String get title => S.current.swap;

  @override
  bool get gradientBackground => true;

  @override
  bool get gradientAll => true;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(BuildContext context) {
    final questionImage = Image.asset('assets/images/question_mark.png',
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor);

    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: TextButton(
            // FIX-ME: Style
            //highlightColor: Colors.transparent,
            //splashColor: Colors.transparent,
            //padding: EdgeInsets.all(0),
            onPressed: () => showInformation(exchangeTradeViewModel, context),
            child: questionImage),
      ),
    );
  }

  @override
  Widget body(BuildContext context) =>
      ExchangeTradeForm(exchangeTradeViewModel);
}

class ExchangeTradeForm extends StatefulWidget {
  ExchangeTradeForm(this.exchangeTradeViewModel);

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  ExchangeTradeState createState() => ExchangeTradeState();
}

class ExchangeTradeState extends State<ExchangeTradeForm> {
  final fetchingLabel = S.current.fetching;

  String get title => S.current.exchange;

  bool _effectsInstalled = false;

  ReactionDisposer? _exchangeStateReaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
  }

  void afterLayout(dynamic _) {
    showInformation(widget.exchangeTradeViewModel, context);
  }

  @override
  void dispose() {
    widget.exchangeTradeViewModel.timer?.cancel();
    _exchangeStateReaction?.reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setEffects();

    return Container(
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(top: 10, bottom: 16),
          content: Observer(builder: (_) {
            final trade = widget.exchangeTradeViewModel.trade;

            return Column(
              children: <Widget>[
                trade.expiredAt != null
                    ? Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                            Text(
                              S.of(context).offer_expires_in,
                              style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor),
                            ),
                            if (trade.expiredAt != null)
                              TimerWidget(trade.expiredAt!,
                                  color: Theme.of(context).extension<CakeTextTheme>()!.titleColor)
                          ])
                    : Offstage(),
                _ExchangeTradeItemsCardSection(viewModel: widget.exchangeTradeViewModel),
              ],
            );
          }),
          bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          bottomSection: Observer(builder: (_) {
            final trade = widget.exchangeTradeViewModel.trade;
            final sendingState =
                widget.exchangeTradeViewModel.sendViewModel.state;

            return widget.exchangeTradeViewModel.isSendable &&
                    !(sendingState is TransactionCommitted)
                ? LoadingPrimaryButton(
                    key: ValueKey('exchange_trade_page_confirm_sending_button_key'),
                    isDisabled: trade.inputAddress == null ||
                        trade.inputAddress!.isEmpty,
                    isLoading: sendingState is IsExecutingState,
                    onPressed: () =>
                        widget.exchangeTradeViewModel.confirmSending(),
                    text: S.of(context).confirm,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white)
                : Offstage();
          })),
    );
  }

  void _setEffects() {
    if (_effectsInstalled) {
      return;
    }

    _exchangeStateReaction = reaction((_) => this.widget.exchangeTradeViewModel.sendViewModel.state,
        (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext popupContext) {
                return AlertWithOneAction(
                    key: ValueKey('exchange_trade_page_send_failure_dialog_key'),
                    buttonKey: ValueKey('exchange_trade_page_send_failure_dialog_button_key'),
                    alertTitle: S.of(popupContext).error,
                    alertContent: state.error,
                    buttonText: S.of(popupContext).ok,
                    buttonAction: () => Navigator.of(popupContext).pop());
              });
        });
      }

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext popupContext) {
                return ConfirmSendingAlert(
                    key: ValueKey('exchange_trade_page_confirm_sending_dialog_key'),
                    alertLeftActionButtonKey: ValueKey('exchange_trade_page_confirm_sending_dialog_cancel_button_key'),
                    alertRightActionButtonKey: 
                    ValueKey('exchange_trade_page_confirm_sending_dialog_send_button_key'),
                    alertTitle: S.of(popupContext).confirm_sending,
                    amount: S.of(popupContext).send_amount,
                    amountValue: widget.exchangeTradeViewModel.sendViewModel
                        .pendingTransaction!.amountFormatted,
                    fee: S.of(popupContext).send_fee,
                    feeValue: widget.exchangeTradeViewModel.sendViewModel
                        .pendingTransaction!.feeFormatted,
                    feeRate: widget.exchangeTradeViewModel.sendViewModel.pendingTransaction!.feeRate,
                    rightButtonText: S.of(popupContext).send,
                    leftButtonText: S.of(popupContext).cancel,
                    actionRightButton: () async {
                      Navigator.of(popupContext).pop();
                      await widget.exchangeTradeViewModel.sendViewModel
                          .commitTransaction(context);
                      transactionStatePopup();
                    },
                    actionLeftButton: () => Navigator.of(popupContext).pop(),
                    feeFiatAmount: widget.exchangeTradeViewModel
                        .pendingTransactionFeeFiatAmountFormatted,
                    fiatAmountValue: widget.exchangeTradeViewModel
                        .pendingTransactionFiatAmountValueFormatted,
                    outputs: widget.exchangeTradeViewModel.sendViewModel
                                 .outputs);
              });
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showPopUp<void>(
                context: context,
                builder: (BuildContext popupContext) {
                  return AlertWithOneAction(
                      alertTitle: S.of(popupContext).sending,
                      alertContent: S.of(popupContext).transaction_sent,
                      buttonText: S.of(popupContext).ok,
                      buttonAction: () => Navigator.of(popupContext).pop());
                });
          }
        });
      }
    });

    _effectsInstalled = true;
  }

  void transactionStatePopup() {
    if (this.mounted) {
      showPopUp<void>(
        context: context,
        builder: (BuildContext popupContext) {
          return Observer(builder: (_) {
            final state = widget
                .exchangeTradeViewModel.sendViewModel.state;

            if (state is TransactionCommitted) {
              return Stack(
                children: <Widget>[
                  Container(
                    color: Theme.of(popupContext).colorScheme.background,
                    child: Center(
                      child: Image.asset(
                          'assets/images/birthday_cake.png'),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 220, left: 24, right: 24),
                      child: Text(
                        S.of(popupContext).send_success(widget
                            .exchangeTradeViewModel
                            .wallet
                            .currency
                            .toString()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(popupContext).extension<CakeTextTheme>()!.titleColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: PrimaryButton(
                          onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                popupContext,
                                Routes.dashboard,
                                (route) => false,
                              );
                            RequestReviewHandler.requestReview();
                          },
                          text: S.of(popupContext).got_it,
                          color: Theme.of(popupContext).primaryColor,
                          textColor: Colors.white))
                ],
              );
            }

            return Stack(
              children: <Widget>[
                Container(
                  color: Theme.of(popupContext).colorScheme.background,
                  child: Center(
                    child: Image.asset(
                        'assets/images/birthday_cake.png'),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 3.0, sigmaY: 3.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(popupContext)
                            .colorScheme
                            .background
                            .withOpacity(0.25)),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 220),
                        child: Text(
                          S.of(popupContext).send_sending,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(popupContext).extension<CakeTextTheme>()!.titleColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          });
        });
    }
  }
}

class _ExchangeTradeItemsCardSection extends StatelessWidget {
  const _ExchangeTradeItemsCardSection({required this.viewModel});

  final ExchangeTradeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final firstExchangeCard = ExchangeTradeCardItemWidget(
      isReceiveDetailsCard: true,
      exchangeTradeViewModel: viewModel,
    );

    final secondExchangeCard = ExchangeTradeCardItemWidget(
      isReceiveDetailsCard: false,
      exchangeTradeViewModel: viewModel,
    );

    if (responsiveLayoutUtil.shouldRenderMobileUI) {
      return MobileExchangeCardsSection(
        firstExchangeCard: firstExchangeCard,
        secondExchangeCard: secondExchangeCard,
      );
    }

    return DesktopExchangeCardsSection(
      firstExchangeCard: firstExchangeCard,
      secondExchangeCard: secondExchangeCard,
    );
  }
}
