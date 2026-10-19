import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/settings/derivation_recovery_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

/// Scans for funds sent to addresses this wallet doesn't use, and moves them into the wallet.
class DerivationRecoveryPage extends StatelessWidget {
  const DerivationRecoveryPage(this._viewModel);

  final DerivationRecoveryViewModel _viewModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          ModalTopBar(
            title: S.current.recover_funds_other_paths,
            leadingIcon: const Icon(Icons.arrow_back_ios_new),
            leadingSemanticLabel: S.current.seed_alert_back,
            onLeadingPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Observer(
                builder: (_) {
                  final scan = _viewModel.scan;
                  final state = _viewModel.state;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.current.recover_funds_other_paths_description,
                        style: textTheme.bodyMedium,
                      ),
                      if (_viewModel.isBusy || _viewModel.checkedAddresses > 0) ...[
                        const SizedBox(height: 16),
                        Text(
                          S.current.addresses_checked(_viewModel.checkedAddresses.toString()),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                      if (scan != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          scan.total > 0
                              ? S.current.funds_found_on_other_paths(
                                  _viewModel.formatAmount(scan.total),
                                )
                              : S.current.no_funds_found_on_other_paths,
                          style: textTheme.titleMedium,
                        ),
                        for (final funds in scan.funds)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${funds.path}  ${funds.addressType}  "
                                    "${funds.seedType == "bip39" ? "BIP39" : "Electrum"}",
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  _viewModel.formatAmount(funds.amount),
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        if (scan.unrecoverableTotal > 0) ...[
                          const SizedBox(height: 16),
                          Text(
                            S.current.unrecoverable_funds_on_wallet_addresses(
                              _viewModel.formatAmount(scan.unrecoverableTotal),
                            ),
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ],
                      if (state is FailureState) ...[
                        const SizedBox(height: 16),
                        Text(
                          state.error,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Observer(
              builder: (_) => LoadingPrimaryButton(
                isLoading: _viewModel.isBusy,
                text: _viewModel.hasFundsToMove
                    ? S.current.move_funds_to_this_wallet
                    : S.current.scan,
                onPressed: () =>
                    _viewModel.hasFundsToMove ? _moveFunds(context) : _viewModel.startScan(),
                color: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveFunds(BuildContext context) async {
    await _viewModel.createSweep();
    final sweep = _viewModel.pendingSweep;
    if (sweep == null || !context.mounted) {
      return;
    }

    final confirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.current.confirm_sending,
        alertContent: "${S.current.amount}${sweep.amount.toStringWithSymbol()}\n"
            "${S.current.fee}: ${sweep.feeFormatted}",
        rightButtonText: S.current.confirm,
        leftButtonText: S.current.cancel,
        actionRightButton: () => Navigator.of(dialogContext).pop(true),
        actionLeftButton: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (confirmed != true) {
      return;
    }

    await _viewModel.commitSweep();
    if (_viewModel.state is! ExecutedSuccessfullyState || !context.mounted) {
      return;
    }

    await showPopUp<void>(
      context: context,
      builder: (dialogContext) => AlertWithOneAction(
        alertTitle: S.current.recover_funds_other_paths,
        alertContent: S.current.transaction_sent,
        buttonText: S.current.ok,
        buttonAction: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
