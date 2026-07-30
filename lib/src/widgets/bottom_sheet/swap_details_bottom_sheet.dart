import "dart:async";

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/exchange/trade.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/standard_slide_button_widget.dart";
import "package:cake_wallet/utils/address_formatter.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/send/send_view_model_state.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";

class SwapDetailsBottomSheet extends StatefulWidget {
  const SwapDetailsBottomSheet({
 required this.bloc, super.key,
  });

  final SwapBloc bloc;

  @override
  State<SwapDetailsBottomSheet> createState() => _SwapDetailsBottomSheetState();
}

class _SwapDetailsBottomSheetState extends State<SwapDetailsBottomSheet> {
  bool _effectsInstalled = false;
  ReactionDisposer? _exchangeStateReaction;
  BuildContext? _loadingBottomSheetContext;
  bool _showingFailureDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setEffects();
      }
    });
  }

  @override
  void dispose() {
    _exchangeStateReaction?.reaction.dispose();
    super.dispose();
  }

  void _setEffects() {
    if (_effectsInstalled) {
      printV("Swap details bottom sheet effects already installed");
      return;
    }

    final initialState = widget.bloc.state;

    if (initialState is SwapFailure && !_showingFailureDialog) {
      _showingFailureDialog = true;
      printV("Initial failure state: $initialState");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          showPopUp<void>(
            context: context,
            builder: (popupContext) => AlertWithOneAction(
                key: const ValueKey("swap_details_send_failure_dialog_key"),
                buttonKey: const ValueKey("swap_details_send_failure_dialog_button_key"),
                alertTitle: S.of(popupContext).error,
                alertContent: initialState.error.toString(),
                buttonText: S.of(popupContext).ok,
                buttonAction: () {
                  _showingFailureDialog = false;
                  Navigator.of(popupContext).pop();
                },
              ),
          );
        } else {
          _showingFailureDialog = false;
        }
      });
    }
    

    _effectsInstalled = true;
  }

  @override
  Widget build(BuildContext context) => _SwapDetailsBottomSheetContent(
      titleText: "Confirm Swap",
      footerType: FooterType.none,
      bloc: widget.bloc,
      maxHeight: 900,
      onExecuteSwap: _executeSwap,
    );

  Future<void> _executeSwap() async {

      widget.bloc.add(SendConfirmed());

  }
}

class _SwapDetailsBottomSheetContent extends BaseBottomSheet {
  const _SwapDetailsBottomSheetContent({
    required this.bloc, required super.titleText,
    required super.footerType,
    required super.maxHeight,
    required this.onExecuteSwap,
  });

  final SwapBloc bloc;
  final VoidCallback onExecuteSwap;

  @override
  Widget contentWidget(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
  builder: (context, state) {
    if(state is! SwapStateWithTrade) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _SwapDetailsContent(
          trade: state.trade,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Observer(
            builder: (_) {

              if (state is SwapAwaitingSend || state is SwapSending) {
                return Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  child: Center(
                    child: state is SwapSending
                        ? const CircularProgressIndicator()
                        : Text(
                      "Swipe to swap",
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
                buttonText: "Swipe to swap",
                onSlideComplete: onExecuteSwap,
                accessibleNavigationModeButtonText: "Complete swap",
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  },
);
}

class _SwapDetailsContent extends StatelessWidget {
  const _SwapDetailsContent({required this.trade, });

  final Trade trade;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Observer(
        builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // _SwapDetailsTile(
              //   label: 'You Send',
              //   value: '${trade.depositAmount.toStringWithSymbol()}',
              //   valueFiatFormatted: exchangeTradeViewModel.sendAmountFiatFormatted,
              // ),
              const SizedBox(height: 8),
              _SwapDetailsTile(
                label: "You Get",
                value: trade.payoutAmount.toStringWithSymbol(),
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
                      "To this Address",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    AddressFormatter.buildSegmentedAddress(
                      address: trade.payoutAddress,
                      walletType:
                      cryptoCurrencyOrTokenToWalletType(trade.payoutAmount.currency as CryptoCurrency),
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
                              "ID: ",
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
          ),
      ),
    );
}

class _SwapDetailsTile extends StatelessWidget {
  const _SwapDetailsTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
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
              // if (valueFiatFormatted.isNotEmpty)
              //   Text(
              //     valueFiatFormatted,
              //     style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              //       fontSize: 10,
              //       fontWeight: FontWeight.w600,
              //       color: Theme.of(context).colorScheme.onSurfaceVariant,
              //     ),
              //   ),
            ],
          ),
        ],
      ),
    );
}
