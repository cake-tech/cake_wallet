import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_intro_page.dart";
import "package:cake_wallet/new-ui/pages/everstake/everstake_position_page.dart";
import "package:cake_wallet/new-ui/viewmodels/everstake/everstake_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_earned_text.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_provider_logo.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_provider_tile.dart";
import "package:cake_wallet/new-ui/widgets/everstake/everstake_rows.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class EverstakeDefiTile extends StatelessWidget {
  const EverstakeDefiTile({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt.get<EverstakeBloc>()),
          BlocProvider(create: (_) => getIt.get<FiatRateCubit>(param1: CryptoCurrency.eth)),
        ],
        child: BlocBuilder<EverstakeBloc, EverstakeState>(
          builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
            builder: (context, fiatRate) {
              final data = state.data;

              if (data == null) {
                final failed = state is EverstakeFailure;
                return _tile(
                  subtitle:
                      failed ? (style) => Text(S.of(context).load_failed, style: style) : null,
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
                return _tile(
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

              final amount = data.positionAmount;
              final amountFiat = fiatRate?.convert(amount);

              return _tile(
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
                      DefiEarnedText(data.earned, fiatRate: fiatRate, style: style),
                  ],
                ),
                onTap: () => _open(
                  context,
                  EverstakePositionPage(authService: getIt.get<AuthService>()),
                ),
              );
            },
          ),
        ),
      );

  Widget _tile({
    required Widget Function(TextStyle style) trailing,
    Widget Function(TextStyle style)? subtitle,
    VoidCallback? onTap,
  }) =>
      DefiProviderTile(
        logo: const DefiProviderLogo("assets/images/everstake.png"),
        name: "Everstake",
        trailing: trailing,
        subtitle: subtitle,
        onTap: onTap,
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

    final settled = bloc.state.isBusy
        ? await bloc.stream.firstWhere((state) => !state.isBusy, orElse: () => bloc.state)
        : bloc.state;

    if (!bloc.isClosed && settled is! EverstakeReady) {
      bloc.add(const StakingDataRequested());
    }
  }
}
