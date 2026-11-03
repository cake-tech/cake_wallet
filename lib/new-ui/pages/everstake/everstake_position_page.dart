import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_amount_page.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_confirm_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_position_view.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_rows.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_logo.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_rows.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EverstakePositionPage extends StatefulWidget {
  const EverstakePositionPage({required this.authService, super.key});

  final AuthService authService;

  @override
  State<EverstakePositionPage> createState() => _EverstakePositionPageState();
}

class _EverstakePositionPageState extends State<EverstakePositionPage> {
  bool _preparingClaim = false;
  String? _claimError;

  @override
  Widget build(BuildContext context) => BlocConsumer<EverstakeBloc, EverstakeState>(
        listenWhen: (_, __) => _preparingClaim,
        listener: (context, state) {
          switch (state) {
            case EverstakePrepared(:final operation):
              setState(() => _preparingClaim = false);
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
                _preparingClaim = false;
                _claimError = error;
              });
            case EverstakeReady():
              setState(() => _preparingClaim = false);
            default:
              break;
          }
        },
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final data = state.data!;
            final withdrawal = data.withdrawRequest.requested;
            final canClaim = data.canClaimWithdrawal;

            return DefiPositionView(
              name: "Everstake",
              logo: const EverstakeLogo(),
              amount: data.positionAmount,
              fiatRate: fiatRate,
              sections: {
                "position": [
                  everstakeProviderRow(context),
                  if (data.apr != null) everstakeYieldRow(context, data.apr!),
                  defiEarnedRow(context, data.earned, fiatRate),
                  if (!data.pendingActivation.isZero)
                    defiAmountRow(
                      context,
                      keyValue: "staking_pending_activation",
                      label: S.of(context).pending_activation,
                      amount: data.pendingActivation,
                    ),
                  if (!withdrawal.isZero)
                    defiAmountRow(
                      context,
                      keyValue: "staking_withdrawal",
                      label: canClaim
                          ? S.of(context).ready_to_claim
                          : S.of(context).withdrawal_pending,
                      amount: withdrawal,
                      isLoading: _preparingClaim,
                      labelColor: canClaim ? Theme.of(context).colorScheme.primary : null,
                      onTap: canClaim && !state.isBusy ? _claimWithdrawal : null,
                    ),
                ],
                "terms": [
                  if (data.activationTime != null && !data.pendingActivation.isZero)
                    everstakeActivationRow(context, data.activationTime!),
                  if (!withdrawal.isZero && !canClaim && data.withdrawalTime != null)
                    everstakeWithdrawalTimeRow(context, data.withdrawalTime!),
                  everstakeServiceFeeRow(context, data.poolFee),
                ],
              },
              error: _claimError,
              onWithdraw: data.withdrawableBalance.isZero
                  ? null
                  : () => _openAmountPage(EverstakeAmountMode.withdraw),
              withdrawDisabled: _preparingClaim,
              onDeposit: () => _openAmountPage(EverstakeAmountMode.deposit),
              depositDisabled: _preparingClaim,
            );
          },
        ),
      );

  void _claimWithdrawal() {
    if (_preparingClaim) {
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
          _preparingClaim = true;
          _claimError = null;
        });
        context.read<EverstakeBloc>().add(const WithdrawalClaimRequested());
      },
    );
  }

  void _openAmountPage(EverstakeAmountMode mode) {
    setState(() => _claimError = null);
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
