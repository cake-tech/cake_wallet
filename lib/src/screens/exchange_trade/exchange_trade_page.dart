import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/desktop_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/mobile_exchange_cards_section.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/exchange_trade_card_item_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/confirm_sending_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/utils/request_review_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/exchange_trade/widgets/timer_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';

void showInformation(ExchangeTradeViewModel exchangeTradeViewModel, BuildContext context) {
  final trade = exchangeTradeViewModel.trade;
  final walletName = exchangeTradeViewModel.wallet.name;

  final from = trade.from?.toString() ?? trade.userCurrencyFrom.toString();

  final information = exchangeTradeViewModel.isSendable
      ? S.current.exchange_trade_result_confirm(trade.amount, from, walletName) +
          exchangeTradeViewModel.extraInfo
      : S.current.exchange_result_description(trade.amount, from) +
          exchangeTradeViewModel.extraInfo;

  showPopUp<void>(
    context: context,
    builder: (_) => InformationPage(
      key: ValueKey('information_page_dialog_key'),
      information: information,
    ),
  );
}

class ExchangeTradePage extends BasePage {
  ExchangeTradePage({required this.exchangeTradeViewModel});

  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  String get title => S.current.swap;

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
        color: Theme.of(context).colorScheme.onSurface);

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
  Widget body(BuildContext context) => ExchangeTradeForm(exchangeTradeViewModel);
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
        contentPadding: EdgeInsets.only(bottom: 16),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (trade.expiredAt != null)
                            TimerWidget(trade.expiredAt!,
                                color: Theme.of(context).colorScheme.onSurface)
                        ])
                  : Offstage(),
              _ExchangeTradeItemsCardSection(
                viewModel: widget.exchangeTradeViewModel,
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
              color: widget.exchangeTradeViewModel.isSendable
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : Theme.of(context).colorScheme.primary,
              textColor: widget.exchangeTradeViewModel.isSendable
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onPrimary,
              isDisabled: widget.exchangeTradeViewModel.isSwapsXyzSendingEVMTokenSwap,
            ),
            SizedBox(height: 16),
            Observer(
              builder: (_) {
                final trade = widget.exchangeTradeViewModel.trade;
                final sendingState = widget.exchangeTradeViewModel.sendViewModel.state;

                return Offstage(
                  offstage: !(widget.exchangeTradeViewModel.isSendable &&
                      !(sendingState is TransactionCommitted)),
                  child: LoadingPrimaryButton(
                    key: ValueKey('exchange_trade_page_send_from_cake_button_key'),
                    isDisabled: trade.inputAddress == null || trade.inputAddress!.isEmpty ||
                        sendingState is ExecutedSuccessfullyState,
                    isLoading: sendingState is IsExecutingState,
                    onPressed: () => widget.exchangeTradeViewModel.confirmSending(),
                    text: S.current.send_from_cake_wallet,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  BuildContext? dialogContext;
  BuildContext? loadingBottomSheetContext;

  void _setEffects() {
    if (_effectsInstalled) {
      return;
    }

    _exchangeStateReaction = reaction(
      (_) => this.widget.exchangeTradeViewModel.sendViewModel.state,
      (ExecutionState state) async {
        if (dialogContext != null && dialogContext?.mounted == true) {
          Navigator.of(dialogContext!).pop();
        }

        if (state is! IsExecutingState &&
            loadingBottomSheetContext != null &&
            loadingBottomSheetContext!.mounted) {
          Navigator.of(loadingBottomSheetContext!).pop();
        }

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

        if (state is IsExecutingState) {
          // wait a bit to avoid showing the loading dialog if transaction is failed
          await Future.delayed(const Duration(milliseconds: 300));
          final currentState = widget.exchangeTradeViewModel.sendViewModel.state;
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
            final trade = widget.exchangeTradeViewModel.trade;
            final isSwapsXyz = trade.provider == ExchangeProviderDescription.swapsXyz;
            final isEVMWallet = widget.exchangeTradeViewModel.sendViewModel.isEVMWallet;

            final amountValue = isSwapsXyz && isEVMWallet
                ? trade.amount
                : widget.exchangeTradeViewModel.sendViewModel.pendingTransaction!.amountFormatted;

            if (context.mounted) {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isDismissible: false,
                isScrollControlled: true,
                builder: (BuildContext bottomSheetContext) {
                  return ConfirmSendingBottomSheet(
                    key: ValueKey('exchange_trade_page_confirm_sending_bottom_sheet_key'),
                    footerType: FooterType.slideActionButton,
                    isSlideActionEnabled: widget.exchangeTradeViewModel.sendViewModel.isReadyForSend,
                    walletType: widget.exchangeTradeViewModel.sendViewModel.walletType,
                    titleText: S.of(bottomSheetContext).confirm_transaction,
                    titleIconPath:
                        widget.exchangeTradeViewModel.sendViewModel.selectedCryptoCurrency.iconPath,
                    currency: widget.exchangeTradeViewModel.sendViewModel.selectedCryptoCurrency,
                    amount: S.of(bottomSheetContext).send_amount,
                    amountValue: amountValue,
                    fiatAmountValue: widget
                        .exchangeTradeViewModel.sendViewModel.pendingTransactionFiatAmountFormatted,
                    fee:
                        isEVMCompatibleChain(widget.exchangeTradeViewModel.sendViewModel.walletType)
                            ? S.of(bottomSheetContext).send_estimated_fee
                            : S.of(bottomSheetContext).send_fee,
                    feeValue: widget
                        .exchangeTradeViewModel.sendViewModel.pendingTransaction!.feeFormatted,
                    feeFiatAmount: widget.exchangeTradeViewModel.sendViewModel
                        .pendingTransactionFeeFiatAmountFormatted,
                    outputs: widget.exchangeTradeViewModel.sendViewModel.outputs,
                    onSlideActionComplete: () async {
                      if (bottomSheetContext.mounted) {
                        Navigator.of(bottomSheetContext).pop(true);
                      }
                      widget.exchangeTradeViewModel.sendViewModel.commitTransaction(context);
                      widget.exchangeTradeViewModel.registerSwapsXyzTransaction();
                    },
                  );
                },
              );

              if  (result == null) widget.exchangeTradeViewModel.sendViewModel.dismissTransaction();

            }
          });
        }

        if (state is TransactionCommitted) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) async {
              if (!mounted) return;

              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext bottomSheetContext) {
                  return InfoBottomSheet(
                    footerType: FooterType.singleActionButton,
                    titleText: S.of(bottomSheetContext).transaction_sent,
                    contentImage: 'assets/images/birthday_cake.png',
                    singleActionButtonText: S.of(bottomSheetContext).close,
                    singleActionButtonKey: ValueKey('send_page_sent_dialog_ok_button_key'),
                    onSingleActionButtonPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.dashboard,
                          (route) => false,
                        );
                      }
                      RequestReviewHandler.requestReview();
                    },
                  );
                },
              );
            },
          );
        }
      },
    );

    _effectsInstalled = true;
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
