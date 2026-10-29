import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_amount_page.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_confirm_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_amount_header.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_logo.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_rows.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EverstakeDetailsPage extends StatefulWidget {
  const EverstakeDetailsPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<EverstakeDetailsPage> createState() => _EverstakeDetailsPageState();
}

class _EverstakeDetailsPageState extends State<EverstakeDetailsPage> {
  bool _preparing = false;
  String? _prepareError;

  @override
  Widget build(BuildContext context) => BlocConsumer<EverstakeBloc, EverstakeState>(
        listenWhen: (_, __) => _preparing,
        listener: (context, state) {
          switch (state) {
            case EverstakePrepared(:final operation):
              setState(() => _preparing = false);
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => Material(
                    color: Colors.transparent,
                    child: EverstakeConfirmPage(operation),
                  ),
                ),
              );
            case EverstakeFailure(:final error):
              setState(() {
                _preparing = false;
                _prepareError = error;
              });
            case EverstakeReady():
              setState(() => _preparing = false);
            default:
              break;
          }
        },
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final theme = Theme.of(context);
            final data = state.data!;
            final isBusy = state is EverstakeLoading || state is EverstakePreparing;
            final withdrawal = data.withdrawRequest.requested;
            final canClaim = data.canClaimWithdrawal;

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    ModalTopBar(
                      title: "Everstake",
                      titleLeadingWidget: const EverstakeLogo(),
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
                            EverstakeAmountHeader(data.stakedBalance),
                            NewListSections(
                              sections: {
                                "position": [
                                  everstakeProviderRow(context),
                                  if (data.apr != null) everstakeYieldRow(context, data.apr!),
                                  everstakeEarnedRow(context, data.earned, fiatRate),
                                  if (!data.pendingActivation.isZero)
                                    everstakeAmountRow(
                                      context,
                                      keyValue: "staking_pending_activation",
                                      label: S.of(context).pending_activation,
                                      amount: data.pendingActivation,
                                    ),
                                ],
                                "terms": [
                                  if (data.activationTime != null)
                                    everstakeActivationRow(context, data.activationTime!),
                                  everstakeServiceFeeRow(context, data.poolFee),
                                ],
                                if (!withdrawal.isZero)
                                  "withdrawal": [
                                    everstakeAmountRow(
                                      context,
                                      keyValue: "staking_withdrawal",
                                      label: canClaim
                                          ? S.of(context).ready_to_claim
                                          : S.of(context).withdrawal_pending,
                                      amount: withdrawal,
                                      isLoading: _preparing,
                                      labelColor: canClaim ? theme.colorScheme.primary : null,
                                      onTap: canClaim && !isBusy ? _claimWithdrawal : null,
                                    ),
                                  ],
                              },
                            ),
                            if (_prepareError != null)
                              Text(
                                _prepareError!,
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
                          Expanded(
                            child: NewPrimaryButton(
                              onPressed: () => _openAmountPage(EverstakeAmountMode.withdraw),
                              disabled: _preparing || data.withdrawableBalance.isZero,
                              text: S.of(context).withdraw,
                              color: theme.colorScheme.surfaceContainer,
                              textColor: theme.colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: NewPrimaryButton(
                              onPressed: () => _openAmountPage(EverstakeAmountMode.deposit),
                              disabled: _preparing,
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
              ),
            );
          },
        ),
      );

  void _claimWithdrawal() {
    if (_preparing) {
      return;
    }

    widget.authService.authenticateAction(
      navigatorKey.currentContext ?? context,
      conditionToDetermineIfToUse2FA:
          widget.authService.settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets,
      onAuthSuccess: (authenticated) {
        if (!authenticated || !mounted) {
          return;
        }
        setState(() {
          _preparing = true;
          _prepareError = null;
        });
        context.read<EverstakeBloc>().add(const WithdrawalClaimRequested());
      },
    );
  }

  void _openAmountPage(EverstakeAmountMode mode) {
    setState(() => _prepareError = null);
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => Material(
          color: Colors.transparent,
          child: EverstakeAmountPage(mode: mode, authService: widget.authService),
        ),
      ),
    );
  }
}
