import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/rates/rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/util/swap_address.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_modal_header.dart";
import "package:cake_wallet/new-ui/widgets/swap_page/swap_send_external_modal.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/list_extension.dart";
import "package:cake_wallet/view_model/send/send_view_model_state.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class SwapConfirmSheet extends StatelessWidget {
  const SwapConfirmSheet({required this.bloc, super.key,});


  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SwapBloc, SwapState>(bloc: bloc, builder: (context, state) {
        final commited =
        state is SwapTransactionCommitted;
        return PopScope(
              onPopInvokedWithResult: (didPop, result) {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SafeArea(
                  child: Stack(
                    fit: StackFit.loose,
                    children: [
                      Positioned.fill(
                          child: AnimatedSlide(
                            offset: commited ? Offset.zero : const Offset(1, 0),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: const TransactionCommitedScreen(),
                          )),
                      AnimatedSlide(
                        offset: commited ? const Offset(-1, 0) : Offset.zero,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: SwapTransactionDetails(bloc: bloc
                        ),
                      ),
                    ],
                  ),
                ),
              ));
      });
}

class SwapTransactionDetails extends StatelessWidget {
  const SwapTransactionDetails(
      {required this.bloc, super.key});

  final SwapBloc bloc;


  @override
  Widget build(BuildContext context) => BlocBuilder<SwapBloc, SwapState>(
    bloc: bloc,
  builder: (context, state) {
    if (state is! SwapStateWithInputs) {
      throw StateError("this widget shouldn't be openable at this point! what happened?");
    }

    final provider = switch ((state, bloc.rateCubit.state)) {
      (SwapInputState(), RatesLoaded(:final rates)) => rates.max.provider,
      _ => state.usableProviders.first,
    };
    final tradeId = state is SwapStateWithTrade ? state.trade.id : "...";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalTopBar(
          title: "",
          leadingWidget: SwapModalHeader(
              fromIconPath: state.depositAmount.currency.iconPath ?? "",
              toIconPath: state.payoutAmount.currency.iconPath ?? ""),
          trailingIcon: const Icon(Icons.close),
          trailingSemanticLabel: S.of(context).close,
          onTrailingPressed: Navigator.of(context).maybePop,
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              spacing: 24,
              children: [
                Observer(
                  builder: (_) => NewListSections(showHeader: true, sections: {
                    S.of(context).send: [
                      ListItemRegularRow(
                        showArrow: false,
                        keyValue: "send value",
                        label: state.depositAmount.currency.fullName ?? "",
                        iconPath: state.depositAmount.currency.iconPath ?? "",
                        badgeIconPath: _resolveChainBadgePath(state.depositAmount.currency),
                        trailingText: state.depositAmount.cryptoAmount.toStringWithSymbol(fractionalDigits: 8, trimZeros: true),
                      ),
                      if (state is SwapStateWithTransaction)
                        ListItemRegularRow(
                            showArrow: false,
                            keyValue: "fee",
                            label: S.of(context).fee,
                            trailingText: state.feeFiatAmount.isZero
                                ? state.transaction.feeFormatted
                                : "${state.transaction.feeFormatted} (${state.feeFiatAmount.toStringWithSymbol(fractionalDigits: 2, trimZeros: false)})"),
                      ListItemRegularRow(
                          keyValue: "sender",
                          label: S.of(context).from,
                          trailingText: state.source.displayName,
                          showArrow: false)
                    ],
                    S.of(context).receive: [
                      ListItemRegularRow(
                        showArrow: false,
                        keyValue: "receive value",
                        label: state.payoutAmount.currency.fullName ?? "",
                        iconPath: state.payoutAmount.currency.iconPath ?? "",
                        badgeIconPath: _resolveChainBadgePath(state.payoutAmount.currency),
                        trailingText: state.payoutAmount.cryptoAmount.toStringWithSymbol(fractionalDigits: 8, trimZeros: true),
                      ),
                      ListItemRegularRow(
                          keyValue: "receiver",
                          label: S.of(context).to,
                          showArrow: false,
                          trailingText: switch (state.payoutAddress) {
                            final ExternalSwapAddress address => middleTruncate(address.address, 8, 8),
                            final address? => address.displayName,
                            null => "",
                          }),
                      if (state is SwapStateWithTrade && (state.trade.toAddressExtraId ?? "").isNotEmpty)
                        ListItemRegularRow(
                          keyValue: "receive memo",
                          showArrow: false,
                          label: state.payoutAmount.currency.memoLabelType ==
                                  MemoLabelType.destinationTag
                              ? S.of(context).destination_tag
                              : S.of(context).memo,
                          trailingText: middleTruncate(
                              state.trade.toAddressExtraId ?? "", 8, 8),
                          copyableText: state.trade.toAddressExtraId,
                        ),
                    ],
                    "${S.of(context).swap_id} (${S.of(context).tap_to_copy})": [
                      ListItemRegularRow(
                          showArrow: false,
                          keyValue: "provider",
                          onTap: () {
                            if(state is SwapStateWithTrade) {
                              Clipboard.setData(
                              ClipboardData(text: state.trade.id));
                            }
                          },
                          label: provider.title,
                          iconPath: provider.image,
                          trailingIconPath: "assets/new-ui/copy.svg",
                          trailingText:tradeId.length > 18
                              ? null
                              : tradeId,
                          bottomWidget:tradeId.length <= 18
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    tradeId,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                )),
                      if (provider ==
                          ExchangeProviderDescription.trocador && state is SwapStateWithTrade)
                        ListItemRegularRow(
                            showArrow: false,
                            keyValue: "trocador provider name",
                            label: "Trocador ${S.of(context).provider}",
                            trailingText: state.trade.providerName ?? "")
                    ]
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SwapConfirmBottomWidget(
                          bloc: bloc),
                ),
              ],
            ),
          ),
        )
      ],
    );
  },
);


}

String? _resolveChainBadgePath(CryptoCurrency currency) {
  try {
    if (currency.chainIconPath != null) return currency.chainIconPath;

    final tag = currency.tag;
    if (tag != null && tag.isNotEmpty) {
      final byTag = CryptoCurrency.fromString(tag);
      if (byTag.chainIconPath != null) return byTag.chainIconPath;
    }

    final walletType = cryptoCurrencyOrTokenToWalletType(currency);
    if (walletType != null) {
      return walletTypeToCryptoCurrency(walletType).chainIconPath;
    }
  } catch (_) {}
  return null;
}
