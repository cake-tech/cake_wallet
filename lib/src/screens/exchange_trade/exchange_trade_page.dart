import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/desktop_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/mobile_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/exchange_trade_card_item_widget.dart';
import 'package:cake_wallet/src/screens/send/widgets/confirm_sending_bottom_sheet.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
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
      ? S.current.exchange_trade_result_confirm(trade.amount, trade.from.toString(), walletName) +
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
  Widget body(BuildContext context) => ExchangeTradeForm(
        exchangeTradeViewModel,
        currentTheme,
      );
}

class ExchangeTradeForm extends StatefulWidget {
  ExchangeTradeForm(
    this.exchangeTradeViewModel,
    this.currentTheme,
  );

  final ExchangeTradeViewModel exchangeTradeViewModel;
  final ThemeBase currentTheme;

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
                                color: Theme.of(context)
                                    .extension<TransactionTradeTheme>()!
                                    .detailsTitlesColor),
                          ),
                          if (trade.expiredAt != null)
                            TimerWidget(trade.expiredAt!,
                                color: Theme.of(context).extension<CakeTextTheme>()!.titleColor)
                        ])
                  : Offstage(),
              _ExchangeTradeItemsCardSection(
                viewModel: widget.exchangeTradeViewModel,
                currentTheme: widget.currentTheme,
              ),
            ],
          );
        }),
        bottomSectionPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        bottomSection: Column(
          children: [
            PrimaryButton(
              key: ValueKey('exchange_trade_page_send_from_external_button_key'),
              text: S.current.send_from_external_wallet,
              onPressed: () async {
                Navigator.of(context).pushNamed(Routes.exchangeTradeExternalSendPage);
              },
              color: Theme.of(context).cardColor,
              textColor: Theme.of(context).extension<CakeTextTheme>()!.buttonTextColor,
            ),
            SizedBox(height: 16),
            Observer(
              builder: (_) {
                final trade = widget.exchangeTradeViewModel.trade;
                final sendingState = widget.exchangeTradeViewModel.sendViewModel.state;

                return widget.exchangeTradeViewModel.isSendable &&
                        !(sendingState is TransactionCommitted)
                    ? LoadingPrimaryButton(
                        key: ValueKey('exchange_trade_page_send_from_cake_button_key'),
                        isDisabled: trade.inputAddress == null || trade.inputAddress!.isEmpty,
                        isLoading: sendingState is IsExecutingState,
                        onPressed: () => widget.exchangeTradeViewModel.confirmSending(),
                        text:S.current.send_from_cake_wallet,
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                      )
                    : Offstage();
              },
            ),
          ],
        ),
      ),
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
          if (context.mounted) {
            showModalBottomSheet<void>(
              context: context,
              isDismissible: false,
              isScrollControlled: true,
              builder: (BuildContext bottomSheetContext) {
                return ConfirmSendingBottomSheet(
                  key: ValueKey('exchange_trade_page_confirm_sending_bottom_sheet_key'),
                  titleText: 'Confirm Transaction',
                  titleIconPath: widget.exchangeTradeViewModel.sendViewModel.selectedCryptoCurrency.iconPath,
                  currency: widget.exchangeTradeViewModel.sendViewModel.selectedCryptoCurrency,
                  amount: S.of(bottomSheetContext).send_amount,
                  amountValue: widget.exchangeTradeViewModel.sendViewModel.pendingTransaction!.amountFormatted,
                  fiatAmountValue: widget.exchangeTradeViewModel.sendViewModel.pendingTransactionFiatAmountFormatted,
                  fee: isEVMCompatibleChain(widget.exchangeTradeViewModel.sendViewModel.walletType)
                      ? S.of(bottomSheetContext).send_estimated_fee
                      : S.of(bottomSheetContext).send_fee,
                  feeValue: widget.exchangeTradeViewModel.sendViewModel.pendingTransaction!.feeFormatted,
                  feeFiatAmount: widget.exchangeTradeViewModel.sendViewModel.pendingTransactionFeeFiatAmountFormatted,
                  outputs: widget.exchangeTradeViewModel.sendViewModel.outputs,
                  onSlideComplete: () async {
                    Navigator.of(bottomSheetContext).pop();
                    widget.exchangeTradeViewModel.sendViewModel.commitTransaction(context);
                  },
                );
              },
            );
          }
        });
      }

      if (state is TransactionCommitted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) {
            return;
          }


          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext bottomSheetContext) {
              return TransactionSuccessBottomSheet(
                  context: bottomSheetContext,
                  currentTheme: widget.currentTheme,
                  titleText: 'Transaction Sent',
                  contentImage: 'assets/images/birthday_cake.svg',
                  actionButtonText: S.of(bottomSheetContext).close,
                  actionButtonKey: ValueKey('send_page_sent_dialog_ok_button_key'),
                  actionButton: () {
                    Navigator.of(bottomSheetContext).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      Routes.dashboard,
                      (route) => false,
                    );
                    RequestReviewHandler.requestReview();
                  });
            },
          );

        });
      }

    });

    _effectsInstalled = true;
  }
}

class _ExchangeTradeItemsCardSection extends StatelessWidget {
  const _ExchangeTradeItemsCardSection({
    required this.viewModel,
    required this.currentTheme,
  });

  final ExchangeTradeViewModel viewModel;
  final ThemeBase currentTheme;

  @override
  Widget build(BuildContext context) {
    final firstExchangeCard = ExchangeTradeCardItemWidget(
      currentTheme: currentTheme,
      isReceiveDetailsCard: true,
      exchangeTradeViewModel: viewModel,
    );

    final secondExchangeCard = ExchangeTradeCardItemWidget(
      currentTheme: currentTheme,
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
