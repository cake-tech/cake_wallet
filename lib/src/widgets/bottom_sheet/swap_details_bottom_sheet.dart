import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/exchange/exchange_trade_view_model.dart';
import 'package:cake_wallet/src/widgets/standard_slide_button_widget.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/send/send_view_model_state.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SwapDetailsBottomSheet extends StatefulWidget {
  SwapDetailsBottomSheet({
    Key? key,
    required this.currentTheme,
    required this.exchangeTradeViewModel,
  }) : super(key: key);

  final MaterialThemeBase currentTheme;
  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  State<SwapDetailsBottomSheet> createState() => _SwapDetailsBottomSheetState();
}

class _SwapDetailsBottomSheetState extends State<SwapDetailsBottomSheet> {
  bool _effectsInstalled = false;
  ReactionDisposer? _exchangeStateReaction;
  BuildContext? _loadingBottomSheetContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setEffects());
  }

  @override
  void dispose() {
    widget.exchangeTradeViewModel.timer?.cancel();
    _exchangeStateReaction?.reaction.dispose();
    super.dispose();
  }

  void _setEffects() {
    if (_effectsInstalled) return;

    _exchangeStateReaction = reaction(
      (_) => widget.exchangeTradeViewModel.sendViewModel.state,
      (ExecutionState state) async {
        if (state is! IsExecutingState &&
            state is! TransactionCommitting &&
            _loadingBottomSheetContext != null &&
            _loadingBottomSheetContext!.mounted) {
          Navigator.of(_loadingBottomSheetContext!).pop();
        }

        if (state is FailureState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showPopUp<void>(
              context: context,
              builder: (BuildContext popupContext) {
                return AlertWithOneAction(
                  key: ValueKey('swap_details_send_failure_dialog_key'),
                  buttonKey: ValueKey('swap_details_send_failure_dialog_button_key'),
                  alertTitle: S.of(popupContext).error,
                  alertContent: state.error,
                  buttonText: S.of(popupContext).ok,
                  buttonAction: () => Navigator.of(popupContext).pop(),
                );
              },
            );
          });
        }

        if (state is IsExecutingState) {
          // Wait a bit to avoid showing the loading dialog if transaction is failed
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
                  _loadingBottomSheetContext = context;
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
              await widget.exchangeTradeViewModel.sendViewModel.commitTransaction(context);
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
                    currentTheme: widget.currentTheme,
                    footerType: FooterType.singleActionButton,
                    titleText: S.of(bottomSheetContext).transaction_sent,
                    contentImage: 'assets/images/birthday_cake.png',
                    singleActionButtonText: S.of(bottomSheetContext).close,
                    singleActionButtonKey: ValueKey('swap_details_sent_dialog_ok_button_key'),
                    onSingleActionButtonPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                      ;
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

  @override
  Widget build(BuildContext context) {
    return _SwapDetailsBottomSheetContent(
      titleText: 'Confirm Swap',
      footerType: FooterType.none,
      maxHeight: 900,
      currentTheme: widget.currentTheme,
      exchangeTradeViewModel: widget.exchangeTradeViewModel,
      onExecuteSwap: _executeSwap,
    );
  }

  void _executeSwap() async {
    if (!widget.exchangeTradeViewModel.isSendable) return;

    try {
      await widget.exchangeTradeViewModel.confirmSending();
    } catch (e) {
      printV('Error executing swap: $e');
      if (mounted) {
        showPopUp<void>(
          context: context,
          builder: (BuildContext popupContext) {
            return AlertWithOneAction(
              key: ValueKey('swap_details_execution_error_dialog_key'),
              buttonKey: ValueKey('swap_details_execution_error_dialog_button_key'),
              alertTitle: S.of(popupContext).error,
              alertContent: e.toString(),
              buttonText: S.of(popupContext).ok,
              buttonAction: () => Navigator.of(popupContext).pop(),
            );
          },
        );
      }
    }
  }
}

class _SwapDetailsBottomSheetContent extends BaseBottomSheet {
  _SwapDetailsBottomSheetContent({
    required String titleText,
    required FooterType footerType,
    required double maxHeight,
    MaterialThemeBase? currentTheme,
    required this.exchangeTradeViewModel,
    required this.onExecuteSwap,
  }) : super(
          titleText: titleText,
          footerType: footerType,
          maxHeight: maxHeight,
          currentTheme: currentTheme,
        );

  final ExchangeTradeViewModel exchangeTradeViewModel;
  final VoidCallback onExecuteSwap;

  @override
  Widget contentWidget(BuildContext context) {
    return Column(
      children: [
        _SwapDetailsContent(
          trade: exchangeTradeViewModel.trade,
          exchangeTradeViewModel: exchangeTradeViewModel,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Observer(
            builder: (_) {
              final sendingState = exchangeTradeViewModel.sendViewModel.state;
              final isDisabled = !exchangeTradeViewModel.isSendable ||
                  exchangeTradeViewModel.trade.inputAddress == null ||
                  exchangeTradeViewModel.trade.inputAddress!.isEmpty;

              if (isDisabled || sendingState is IsExecutingState) {
                return Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Center(
                    child: sendingState is IsExecutingState
                        ? CircularProgressIndicator()
                        : Text(
                            'Swipe to swap',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                  ),
                );
              }

              return StandardSlideButton(
                tileBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                knobColor: Theme.of(context).colorScheme.primary,
                buttonText: 'Swipe to swap',
                onSlideComplete: onExecuteSwap,
                currentTheme: currentTheme!,
                accessibleNavigationModeButtonText: 'Complete swap',
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SwapDetailsContent extends StatelessWidget {
  const _SwapDetailsContent({required this.trade, required this.exchangeTradeViewModel});

  final Trade trade;
  final ExchangeTradeViewModel exchangeTradeViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Observer(
        builder: (_) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SwapDetailsTile(
                label: 'You Send',
                value: '${trade.amount} ${trade.from?.title ?? ''}',
                valueFiatFormatted: exchangeTradeViewModel.sendAmountFiatFormatted,
              ),
              const SizedBox(height: 8),
              _SwapDetailsTile(
                label: 'You Get',
                value: '${trade.receiveAmount ?? '0'} ${trade.to?.title ?? ''}',
                valueFiatFormatted: exchangeTradeViewModel
                    .getReceiveAmountFiatFormatted(trade.receiveAmount ?? '0.0'),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To this Address',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    AddressFormatter.buildSegmentedAddress(
                      address: trade.payoutAddress ?? '',
                      walletType: trade.to != null ? cryptoCurrencyToWalletType(trade.to!) : null,
                      evenTextStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CakeImageWidget(
                          imageUrl: trade.provider.image,
                          width: 36,
                          height: 36,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trade.provider.title,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: trade.id));
                          showBar<void>(context, S.of(context).copied_to_clipboard);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'ID: ',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 18),
                            ),
                            Flexible(
                              child: Text(
                                trade.id,
                                style:
                                    Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SwapDetailsTile extends StatelessWidget {
  const _SwapDetailsTile({
    required this.label,
    required this.value,
    required this.valueFiatFormatted,
  });

  final String label;
  final String value;
  final String valueFiatFormatted;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
              ),
              if (valueFiatFormatted.isNotEmpty)
                Text(
                  valueFiatFormatted,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
