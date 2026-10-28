import "package:cake_wallet/core/utilities.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/ethereum_staking/ethereum_staking_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/confirm_swiper.dart";
import "package:cake_wallet/new-ui/widgets/ethereum_staking/ethereum_staking_amount_header.dart";
import "package:cake_wallet/new-ui/widgets/ethereum_staking/ethereum_staking_rows.dart";
import "package:cake_wallet/new-ui/widgets/ethereum_staking/everstake_terms_text.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_bottom_widget.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_confirm_sheet.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

enum _Phase { review, submitting, submitted, failed }

class EthereumStakingConfirmPage extends StatefulWidget {
  const EthereumStakingConfirmPage(this.operation, {super.key});

  final EthereumStakingOperation operation;

  @override
  State<EthereumStakingConfirmPage> createState() => _EthereumStakingConfirmPageState();
}

class _EthereumStakingConfirmPageState extends State<EthereumStakingConfirmPage> {
  static final _minQueuedAmount = Money(BigInt.from(1000000000), CryptoCurrency.eth);

  _Phase _phase = _Phase.review;
  String? _error;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _phase == _Phase.review || _phase == _Phase.failed,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        child: BlocListener<EthereumStakingBloc, EthereumStakingState>(
          listener: (context, state) {
            switch (state) {
              case EthereumStakingSubmitting(:final operation)
                  when identical(operation, widget.operation):
                setState(() => _phase = _Phase.submitting);
              case EthereumStakingSubmitted(:final operation)
                  when identical(operation, widget.operation):
                setState(() => _phase = _Phase.submitted);
              case EthereumStakingFailure(:final error) when _phase == _Phase.submitting:
                setState(() {
                  _phase = _Phase.failed;
                  _error = error;
                });
              default:
                break;
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: SafeArea(
              child: _phase == _Phase.submitted
                  ? const Center(
                      child: TransactionCommitedScreen(),
                    )
                  : BlocBuilder<EthereumStakingBloc, EthereumStakingState>(
                      builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
                        builder: (context, fiatRate) =>
                            _buildReview(context, state.data!, fiatRate),
                      ),
                    ),
            ),
          ),
        ),
      );

  Widget _buildReview(
    BuildContext context,
    EthereumStakingData data,
    ExchangeRate? fiatRate,
  ) {
    final bloc = context.read<EthereumStakingBloc>();
    final queued = _queuedAmount;

    return Column(
      children: [
        ModalTopBar(
          title: switch (widget.operation.action) {
            EthereumStakingAction.stake => S.of(context).confirm_deposit,
            EthereumStakingAction.unstake ||
            EthereumStakingAction.unstakePending =>
              S.of(context).confirm_withdrawal,
            EthereumStakingAction.claimWithdrawal => S.of(context).confirm_claim,
          },
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
                EthereumStakingAmountHeader(
                  widget.operation.amount,
                  approximate: true,
                  isHiddenAmount: false,
                ),
                NewListSections(
                  sections: {
                    "account": [
                      stakingTextRow(
                        context,
                        keyValue: "staking_wallet",
                        label: S.of(context).wallet,
                        value: bloc.walletName,
                      ),
                      stakingTextRow(
                        context,
                        keyValue: "staking_address",
                        label: S.of(context).address,
                        value: middleTruncate(bloc.address, 7, 7),
                        copyableText: bloc.address,
                      ),
                    ],
                    "details": [
                      everstakeProviderRow(context),
                      ..._actionRows(context, data, fiatRate, queued),
                      stakingNetworkFeeRow(context, widget.operation.transaction.fee, fiatRate),
                    ],
                  },
                ),
                if (queued != null)
                  Text(
                    S.of(context).withdrawal_queue_note,
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
              if (_phase != _Phase.failed)
                EverstakeTermsText(S.of(context).everstake_terms_by_swiping),
              switch (_phase) {
                _Phase.review => ConfirmSwiper(
                    onConfirmed: () => bloc.add(TransactionConfirmed(widget.operation)),
                    swiperText: switch (widget.operation.action) {
                      EthereumStakingAction.stake => S.of(context).swipe_to_deposit,
                      EthereumStakingAction.unstake ||
                      EthereumStakingAction.unstakePending =>
                        S.of(context).swipe_to_withdraw,
                      EthereumStakingAction.claimWithdrawal => S.of(context).swipe_to_claim,
                    },
                    accessibleNavigationModeButtonText: S.of(context).confirm,
                  ),
                _Phase.submitting || _Phase.submitted => LoadingBottomWidget(
                    text: "${S.of(context).sending}...",
                  ),
                _Phase.failed => TransactionErrorActions(errorText: _error!),
              },
            ],
          ),
        ),
      ],
    );
  }

  List<ListItem> _actionRows(
    BuildContext context,
    EthereumStakingData data,
    ExchangeRate? fiatRate,
    Money? queued,
  ) =>
      switch (widget.operation.action) {
        EthereumStakingAction.stake => [
            if (data.apr != null) stakingYieldRow(context, data.apr!, approximate: true),
            if (data.activationTime != null) stakingActivationRow(context, data.activationTime!),
            stakingServiceFeeRow(context, data.poolFee),
          ],
        EthereumStakingAction.unstake || EthereumStakingAction.unstakePending => [
            stakingEarnedRow(context, data.earned, fiatRate, isHiddenAmount: false),
            if (queued != null) ...[
              if (widget.operation.amount > queued)
                stakingAmountRow(
                  context,
                  keyValue: "staking_withdrawn_instantly",
                  label: S.of(context).withdrawn_instantly,
                  amount: widget.operation.amount - queued,
                  isHiddenAmount: false,
                ),
              stakingAmountRow(
                context,
                keyValue: "staking_withdrawal_queue",
                label: S.of(context).withdrawal_queue,
                amount: queued,
                isHiddenAmount: false,
              ),
            ],
          ],
        EthereumStakingAction.claimWithdrawal => [],
      };

  Money? get _queuedAmount {
    final instant = widget.operation.instantUnstakeAmount;
    if (instant == null) {
      return null;
    }

    final queued = widget.operation.amount - instant;
    return queued > _minQueuedAmount ? queued : null;
  }
}
