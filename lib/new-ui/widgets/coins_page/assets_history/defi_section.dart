import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_details_page.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_intro_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_logo.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_rows.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart";
import "package:cake_wallet/themes/core/custom_theme_colors.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class DefiSection extends StatelessWidget {
  const DefiSection({super.key});

  static bool supportsWallet(WalletBase wallet) =>
      isEVMCompatibleChain(wallet.type) && wallet.chainId == 1 && !wallet.isHardwareWallet;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt.get<EverstakeBloc>()),
          BlocProvider(create: (_) => getIt.get<FiatRateCubit>(param1: CryptoCurrency.eth)),
        ],
        child: const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 64),
            child: _EverstakeRow(),
          ),
        ),
      );
}

class _EverstakeRow extends StatelessWidget {
  const _EverstakeRow();

  @override
  Widget build(BuildContext context) => BlocBuilder<EverstakeBloc, EverstakeState>(
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final data = state.data;

            if (data == null) {
              final failed = state is EverstakeFailure;
              return _row(
                context,
                subtitle: failed ? (style) => Text(S.of(context).load_failed, style: style) : null,
                trailing: failed
                    ? (style) => Text(
                          S.of(context).try_again,
                          style: style.copyWith(color: Theme.of(context).colorScheme.primary),
                        )
                    : (_) => const CupertinoActivityIndicator(),
                onTap: failed
                    ? () => context.read<EverstakeBloc>().add(const StakingDataRequested())
                    : null,
              );
            }

            if (!data.hasPosition) {
              return _row(
                context,
                subtitle: data.apr == null
                    ? null
                    : (style) => Text(everstakeAprText(context, data.apr!), style: style),
                trailing: (style) => Text(S.of(context).setup, style: style),
                onTap: () => _open(
                  context,
                  EverstakeIntroPage(authService: getIt.get<AuthService>()),
                ),
              );
            }

            final amount =
                data.stakedBalance.isZero ? data.withdrawRequest.requested : data.stakedBalance;
            final amountFiat = fiatRate?.convert(amount);
            final earnedFiat = fiatRate?.convert(data.earned);

            return _row(
              context,
              subtitle: (style) => MoneyText(amount, style: style),
              trailing: (style) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amountFiat != null)
                    MoneyText(amountFiat, fractionalDigits: 2, trimZeros: false, style: style),
                  if (data.canClaimWithdrawal)
                    Text(
                      S.of(context).ready_to_claim,
                      style: style.copyWith(color: Theme.of(context).colorScheme.primary),
                    )
                  else if (data.stakedBalance.isZero)
                    Text(S.of(context).withdrawal_pending, style: style)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("+", style: style.copyWith(color: CustomThemeColors.syncGreen)),
                        MoneyText(
                          earnedFiat ?? data.earned,
                          fractionalDigits: earnedFiat == null ? 8 : 2,
                          trimZeros: earnedFiat == null,
                          style: style.copyWith(color: CustomThemeColors.syncGreen),
                        ),
                      ],
                    ),
                ],
              ),
              onTap: () => _open(
                context,
                EverstakeDetailsPage(authService: getIt.get<AuthService>()),
              ),
            );
          },
        ),
      );

  Widget _row(
    BuildContext context, {
    required Widget Function(TextStyle style) trailing,
    Widget Function(TextStyle style)? subtitle,
    VoidCallback? onTap,
  }) =>
      MergeSemantics(
        child: Semantics(
          button: onTap != null,
          child: ListItemStyleWrapper(
            isFirstInSection: true,
            isLastInSection: true,
            onTap: onTap,
            builder: (context, textStyle, labelStyle) => Row(
              spacing: 12,
              children: [
                const EverstakeLogo(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Text("Everstake", style: textStyle),
                      if (subtitle != null) subtitle(labelStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                trailing(labelStyle),
                if (onTap != null)
                  CakeImageWidget(
                    imageUrl: "assets/new-ui/arrow_forward.svg",
                    height: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      );

  Future<void> _open(BuildContext context, Widget rootPage) async {
    final bloc = context.read<EverstakeBloc>();
    final fiatRate = context.read<FiatRateCubit>();
    bloc.add(const StakingDataRequested());

    await CupertinoScaffold.showCupertinoModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(60),
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: fiatRate),
        ],
        child: ModalNavigator(
          parentContext: sheetContext,
          rootPage: Material(color: Colors.transparent, child: rootPage),
        ),
      ),
    );

    bool isBusy(EverstakeState state) =>
        state is EverstakeLoading || state is EverstakePreparing || state is EverstakeSubmitting;
    final settled = isBusy(bloc.state)
        ? await bloc.stream.firstWhere((state) => !isBusy(state), orElse: () => bloc.state)
        : bloc.state;

    if (!bloc.isClosed && settled is! EverstakeReady) {
      bloc.add(const StakingDataRequested());
    }
  }
}
