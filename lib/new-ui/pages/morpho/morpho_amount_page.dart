import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_confirm_page.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_amount_view.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_badge.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

enum MorphoAmountMode { deposit, withdraw }

class MorphoAmountPage extends StatefulWidget {
  const MorphoAmountPage({required this.mode, required this.authService, super.key});

  final MorphoAmountMode mode;
  final AuthService authService;

  @override
  State<MorphoAmountPage> createState() => _MorphoAmountPageState();
}

class _MorphoAmountPageState extends State<MorphoAmountPage> {
  bool _preparingTransaction = false;
  String? _prepareTransactionError;

  bool get _isDeposit => widget.mode == MorphoAmountMode.deposit;

  @override
  Widget build(BuildContext context) => BlocConsumer<MorphoBloc, MorphoState>(
        listenWhen: (_, __) => _preparingTransaction,
        listener: (context, state) {
          switch (state) {
            case MorphoPrepared(:final operation):
              setState(() => _preparingTransaction = false);
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => Material(
                    color: Colors.transparent,
                    child: MorphoConfirmPage(operation),
                  ),
                ),
              );
            case MorphoFailure(:final error):
              setState(() {
                _preparingTransaction = false;
                _prepareTransactionError = error;
              });
            default:
              break;
          }
        },
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final data = state.data!;
            final maxAmount =
                _isDeposit ? data.walletBalance : data.withdrawableNow ?? data.positionValue;
            final withdrawsAll = !_isDeposit && maxAmount == data.positionValue;

            return DefiAmountView(
              maxAmount: maxAmount,
              maxLabel: _isDeposit
                  ? S.of(context).max
                  : withdrawsAll
                      ? S.of(context).deposited
                      : S.of(context).available,
              maxChipLabel: withdrawsAll ? S.of(context).all_pascal_case : S.of(context).max,
              hint: withdrawsAll ? S.of(context).withdraw_all_or_partial : null,
              fiatRate: fiatRate,
              error: _prepareTransactionError,
              isLoading: _preparingTransaction,
              disabled: !_preparingTransaction && state.isBusy,
              onChanged: () => setState(() => _prepareTransactionError = null),
              onContinue: (amount, {required isMax}) => _prepareTransaction(
                _isDeposit
                    ? DepositRequested(amount)
                    : isMax && withdrawsAll
                        ? const WithdrawAllRequested()
                        : WithdrawRequested(amount),
              ),
              attribution: const MorphoBadge(),
            );
          },
        ),
      );

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
        if (!authenticated || !mounted || context.read<MorphoBloc>().state.isTransacting) {
          return;
        }
        setState(() {
          _preparingTransaction = true;
          _prepareTransactionError = null;
        });
        context.read<MorphoBloc>().add(event);
      },
    );
  }
}
