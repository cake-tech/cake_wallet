import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_confirm_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_amount_view.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

enum EverstakeAmountMode { deposit, withdraw }

class EverstakeAmountPage extends StatefulWidget {
  const EverstakeAmountPage({required this.mode, required this.authService, super.key});

  final EverstakeAmountMode mode;
  final AuthService authService;

  @override
  State<EverstakeAmountPage> createState() => _EverstakeAmountPageState();
}

class _EverstakeAmountPageState extends State<EverstakeAmountPage> {
  bool _preparingTransaction = false;
  String? _prepareTransactionError;

  bool get _isDeposit => widget.mode == EverstakeAmountMode.deposit;

  @override
  Widget build(BuildContext context) => BlocConsumer<EverstakeBloc, EverstakeState>(
        listenWhen: (_, __) => _preparingTransaction,
        listener: (context, state) {
          switch (state) {
            case EverstakePrepared(:final operation):
              setState(() => _preparingTransaction = false);
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
                _preparingTransaction = false;
                _prepareTransactionError = error;
              });
            case EverstakeReady():
              setState(() => _preparingTransaction = false);
            default:
              break;
          }
        },
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final data = state.data!;
            final locale = Localizations.localeOf(context).toString();

            return DefiAmountView(
              maxAmount: _isDeposit ? data.walletBalance : data.withdrawableBalance,
              maxLabel: _isDeposit
                  ? S.of(context).max
                  : data.withdrawsPendingStake
                      ? S.of(context).pending_activation
                      : S.of(context).staked,
              maxChipLabel: _isDeposit ? S.of(context).max : S.of(context).all_pascal_case,
              hint: _isDeposit
                  ? S.of(context).min_amount(
                        data.minStakeAmount.toLocalStringWithSymbol(locale: locale),
                      )
                  : S.of(context).withdraw_all_or_partial,
              fiatRate: fiatRate,
              error: _prepareTransactionError,
              isLoading: _preparingTransaction,
              disabled: !_preparingTransaction && state.isBusy,
              onChanged: () => setState(() => _prepareTransactionError = null),
              onContinue: (amount, {required isMax}) => _continue(data, amount, isMax: isMax),
            );
          },
        ),
      );

  void _continue(EverstakeData data, Money amount, {required bool isMax}) {
    if (_isDeposit) {
      _prepareTransaction(isMax ? const MaxStakeRequested() : StakeRequested(amount));
    } else if (isMax) {
      _prepareTransaction(MaxUnstakeRequested(pending: data.withdrawsPendingStake));
    } else {
      _prepareTransaction(
        data.withdrawsPendingStake ? PendingUnstakeRequested(amount) : UnstakeRequested(amount),
      );
    }
  }

  void _prepareTransaction(TransactionRequested event) {
    if (_preparingTransaction) {
      return;
    }

    final settings = widget.authService.settingsStore;
    widget.authService.authenticateAction(
      navigatorKey.currentContext ?? context,
      conditionToDetermineIfToUse2FA: _isDeposit
          ? settings.shouldRequireTOTP2FAForSendsToNonContact
          : settings.shouldRequireTOTP2FAForSendsToInternalWallets,
      onAuthSuccess: (authenticated) {
        if (!authenticated || !mounted) {
          return;
        }
        setState(() {
          _preparingTransaction = true;
          _prepareTransactionError = null;
        });
        context.read<EverstakeBloc>().add(event);
      },
    );
  }
}
