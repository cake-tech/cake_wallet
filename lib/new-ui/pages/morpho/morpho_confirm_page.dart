import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_confirm_view.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_rows.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_badge.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_notice_text.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_rows.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MorphoConfirmPage extends StatefulWidget {
  const MorphoConfirmPage(this.operation, {super.key});

  final MorphoOperation operation;

  @override
  State<MorphoConfirmPage> createState() => _MorphoConfirmPageState();
}

class _MorphoConfirmPageState extends State<MorphoConfirmPage> {
  final _feeFiatRate = getIt.get<FiatRateCubit>(param1: CryptoCurrency.eth);

  late MorphoOperation _operation = widget.operation;
  DefiConfirmPhase _phase = const DefiConfirmReview();

  bool get _approvesFirst => widget.operation.action == MorphoAction.approve;

  bool get _isApproval => _operation.action == MorphoAction.approve;

  @override
  void dispose() {
    _feeFiatRate.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<MorphoBloc, MorphoState>(
        listener: (context, state) {
          switch (state) {
            case MorphoSubmitting(:final operation) when identical(operation, _operation):
              setState(() => _phase = const DefiConfirmSubmitting());
            case MorphoConfirming(:final operation)
                when identical(operation, _operation) && !_isApproval:
              setState(() => _phase = const DefiConfirmSubmitted());
            case MorphoPrepared(:final operation)
                when _isApproval && _phase is DefiConfirmSubmitting:
              setState(() {
                _operation = operation;
                _phase = const DefiConfirmReview();
              });
            case MorphoFailure(:final error)
                when _phase is DefiConfirmSubmitting || _phase is DefiConfirmSubmitted:
              setState(() => _phase = DefiConfirmFailed(error));
            default:
              break;
          }
        },
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
            bloc: _feeFiatRate,
            builder: (context, feeFiatRate) {
              final bloc = context.read<MorphoBloc>();
              final data = state.data!;
              final isDeposit = _isApproval || _operation.action == MorphoAction.deposit;

              return DefiConfirmView(
                phase: _phase,
                title: isDeposit ? S.of(context).confirm_deposit : S.of(context).confirm_withdrawal,
                bottomText:
                    _approvesFirst ? S.of(context).step_of(_isApproval ? "1" : "2", "2") : null,
                amount: _operation.amount,
                fiatRate: fiatRate,
                walletName: bloc.walletName,
                address: bloc.address,
                details: [
                  morphoProviderRow(context),
                  if (isDeposit && data.apy != null)
                    defiYieldRow(context, morphoApyText(context, data.apy!), approximate: true),
                  if (!isDeposit && data.earned != null)
                    defiEarnedRow(context, data.earned!, fiatRate, isHiddenAmount: false),
                  defiNetworkFeeRow(context, _operation.transaction.fee, feeFiatRate),
                ],
                note: _isApproval
                    ? S.of(context).morpho_approve_deposit_note(MorphoVault.usdcToken.title)
                    : null,
                terms: const MorphoNoticeText(),
                swiperText: switch (_operation.action) {
                  MorphoAction.approve => S.of(context).wc_swipe_to_approve,
                  MorphoAction.deposit => S.of(context).swipe_to_deposit,
                  MorphoAction.withdraw ||
                  MorphoAction.withdrawAll =>
                    S.of(context).swipe_to_withdraw,
                },
                onConfirmed: () => bloc.add(TransactionConfirmed(_operation)),
                attribution: const MorphoBadge(),
              );
            },
          ),
        ),
      );
}
