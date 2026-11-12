import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_confirm_view.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_rows.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_rows.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_terms_text.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EverstakeConfirmPage extends StatefulWidget {
  const EverstakeConfirmPage(this.operation, {super.key});

  final EverstakeOperation operation;

  @override
  State<EverstakeConfirmPage> createState() => _EverstakeConfirmPageState();
}

class _EverstakeConfirmPageState extends State<EverstakeConfirmPage> {
  static final _unstakeDustThreshold = Money(BigInt.from(1000000000), CryptoCurrency.eth); // 1 gwei

  DefiConfirmPhase _phase = const DefiConfirmReview();

  @override
  Widget build(BuildContext context) => BlocConsumer<EverstakeBloc, EverstakeState>(
        listener: (context, state) {
          switch (state) {
            case EverstakeSubmitting(:final operation) when identical(operation, widget.operation):
              setState(() => _phase = const DefiConfirmSubmitting());
            case EverstakeSubmitted(:final operation) when identical(operation, widget.operation):
              setState(() => _phase = const DefiConfirmSubmitted());
            case EverstakeFailure(:final error) when _phase is DefiConfirmSubmitting:
              setState(() => _phase = DefiConfirmFailed(error));
            default:
              break;
          }
        },
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final bloc = context.read<EverstakeBloc>();
            final queued = _queuedUnstakeAmount;

            return DefiConfirmView(
              phase: _phase,
              title: switch (widget.operation.action) {
                EverstakeAction.stake => S.of(context).confirm_deposit,
                EverstakeAction.unstake ||
                EverstakeAction.unstakePending =>
                  S.of(context).confirm_withdrawal,
                EverstakeAction.claimWithdrawal => S.of(context).confirm_claim,
              },
              amount: widget.operation.amount,
              fiatRate: fiatRate,
              walletName: bloc.walletName,
              address: bloc.address,
              details: [
                everstakeProviderRow(context),
                ..._actionRows(context, state.data!, fiatRate, queued),
                defiNetworkFeeRow(context, widget.operation.transaction.fee, fiatRate),
              ],
              note: queued == null ? null : S.of(context).withdrawal_queue_note,
              terms: EverstakeTermsText(S.of(context).everstake_terms_by_swiping),
              swiperText: switch (widget.operation.action) {
                EverstakeAction.stake => S.of(context).swipe_to_deposit,
                EverstakeAction.unstake ||
                EverstakeAction.unstakePending =>
                  S.of(context).swipe_to_withdraw,
                EverstakeAction.claimWithdrawal => S.of(context).swipe_to_claim,
              },
              onConfirmed: () => bloc.add(TransactionConfirmed(widget.operation)),
            );
          },
        ),
      );

  List<ListItem> _actionRows(
    BuildContext context,
    EverstakeData data,
    ExchangeRate? fiatRate,
    Money? queuedUnstakeAmount,
  ) =>
      switch (widget.operation.action) {
        EverstakeAction.stake => [
            if (data.apr != null) everstakeYieldRow(context, data.apr!, approximate: true),
            if (data.activationTime != null) everstakeActivationRow(context, data.activationTime!),
            everstakeServiceFeeRow(context, data.poolFee),
          ],
        EverstakeAction.unstake || EverstakeAction.unstakePending => [
            defiEarnedRow(context, data.earned, fiatRate, isHiddenAmount: false),
            if (queuedUnstakeAmount != null) ...[
              if (widget.operation.amount > queuedUnstakeAmount)
                defiAmountRow(
                  context,
                  keyValue: "staking_withdrawn_instantly",
                  label: S.of(context).withdrawn_instantly,
                  amount: widget.operation.amount - queuedUnstakeAmount,
                  isHiddenAmount: false,
                ),
              defiAmountRow(
                context,
                keyValue: "staking_withdrawal_queue",
                label: S.of(context).withdrawal_queue,
                amount: queuedUnstakeAmount,
                isHiddenAmount: false,
              ),
              if (data.withdrawalTime != null)
                everstakeWithdrawalTimeRow(context, data.withdrawalTime!),
            ],
          ],
        EverstakeAction.claimWithdrawal => [],
      };

  Money? get _queuedUnstakeAmount {
    final instant = widget.operation.instantUnstakeAmount;
    if (instant == null) {
      return null;
    }

    final queued = widget.operation.amount - instant;
    return queued > _unstakeDustThreshold ? queued : null;
  }
}
