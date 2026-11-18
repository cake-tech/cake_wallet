import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_amount_header.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

class DefiPositionView extends StatelessWidget {
  const DefiPositionView({
    required this.name,
    required this.logo,
    required this.amount,
    required this.fiatRate,
    required this.sections,
    required this.onWithdraw,
    required this.onDeposit,
    this.error,
    this.withdrawDisabled = false,
    this.depositDisabled = false,
    super.key,
  });

  final String name;
  final Widget logo;
  final Money amount;
  final ExchangeRate? fiatRate;
  final Map<String, List<ListItem>> sections;
  final VoidCallback? onWithdraw;
  final VoidCallback onDeposit;
  final String? error;
  final bool withdrawDisabled;
  final bool depositDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onWithdraw = this.onWithdraw;

    return DefiScaffold(
      child: Column(
        children: [
          ModalTopBar(
            title: name,
            titleLeadingWidget: logo,
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
                  DefiAmountHeader(amount, fiatRate: fiatRate),
                  NewListSections(sections: sections),
                  if (error != null)
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              spacing: 8,
              children: [
                if (onWithdraw != null)
                  Expanded(
                    child: NewPrimaryButton(
                      onPressed: onWithdraw,
                      disabled: withdrawDisabled,
                      text: S.of(context).withdraw,
                      color: theme.colorScheme.surfaceContainer,
                      textColor: theme.colorScheme.primary,
                    ),
                  ),
                Expanded(
                  child: NewPrimaryButton(
                    onPressed: onDeposit,
                    disabled: depositDisabled,
                    text: S.of(context).deposit,
                    color: theme.colorScheme.primary,
                    textColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
