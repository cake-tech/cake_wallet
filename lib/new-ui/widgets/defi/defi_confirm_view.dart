import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_amount_header.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_rows.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

sealed class DefiConfirmPhase {
  const DefiConfirmPhase();
}

final class DefiConfirmReview extends DefiConfirmPhase {
  const DefiConfirmReview();
}

final class DefiConfirmSubmitting extends DefiConfirmPhase {
  const DefiConfirmSubmitting();
}

final class DefiConfirmSubmitted extends DefiConfirmPhase {
  const DefiConfirmSubmitted();
}

final class DefiConfirmFailed extends DefiConfirmPhase {
  const DefiConfirmFailed(this.error);

  final String error;
}

class DefiConfirmView extends StatelessWidget {
  const DefiConfirmView({
    required this.phase,
    required this.title,
    required this.amount,
    required this.fiatRate,
    required this.walletName,
    required this.address,
    required this.details,
    required this.terms,
    required this.swiperText,
    required this.onConfirmed,
    this.note,
    super.key,
  });

  final DefiConfirmPhase phase;
  final String title;
  final Money amount;
  final ExchangeRate? fiatRate;
  final String walletName;
  final String address;
  final List<ListItem> details;
  final Widget terms;
  final String swiperText;
  final VoidCallback onConfirmed;
  final String? note;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: phase is DefiConfirmReview || phase is DefiConfirmFailed,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        child: DefiScaffold(
          child: phase is DefiConfirmSubmitted
              ? const Center(
                  child: TransactionCommitedScreen(),
                )
              : Column(
                  children: [
                    ModalTopBar(
                      title: title,
                      leadingIcon: const Icon(Icons.close),
                      leadingSemanticLabel: S.of(context).close,
                      onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 64, 18, 24),
                        child: Column(
                          spacing: 24,
                          children: [
                            DefiAmountHeader(
                              amount,
                              fiatRate: fiatRate,
                              approximate: true,
                              isHiddenAmount: false,
                            ),
                            NewListSections(
                              sections: {
                                "account": [
                                  defiTextRow(
                                    context,
                                    keyValue: "defi_wallet",
                                    label: S.of(context).wallet,
                                    value: walletName,
                                  ),
                                  defiTextRow(
                                    context,
                                    keyValue: "defi_address",
                                    label: S.of(context).address,
                                    value: middleTruncate(address, 7, 7),
                                    copyableText: address,
                                  ),
                                ],
                                "details": details,
                              },
                            ),
                            if (note != null)
                              Text(
                                note!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Column(
                        spacing: 16,
                        children: [
                          if (phase is! DefiConfirmFailed) terms,
                          switch (phase) {
                            DefiConfirmReview() => ConfirmSwiper(
                                onConfirmed: onConfirmed,
                                swiperText: swiperText,
                                accessibleNavigationModeButtonText: S.of(context).confirm,
                              ),
                            DefiConfirmSubmitting() ||
                            DefiConfirmSubmitted() =>
                              LoadingBottomWidget(
                                text: "${S.of(context).sending}...",
                              ),
                            DefiConfirmFailed(:final error) =>
                              TransactionErrorActions(errorText: error),
                          },
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      );
}
