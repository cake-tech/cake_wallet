import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_intro_page.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_position_page.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_earned_text.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_provider_logo.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_provider_tile.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_rows.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class MorphoDefiTile extends StatelessWidget {
  const MorphoDefiTile({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt.get<MorphoBloc>()),
          BlocProvider(create: (_) => getIt.get<FiatRateCubit>(param1: MorphoVault.usdcToken)),
        ],
        child: BlocBuilder<MorphoBloc, MorphoState>(
          builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
            builder: (context, fiatRate) {
              final data = state.data;

              if (data == null) {
                final failed = state is MorphoFailure;
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
                      ? () => context.read<MorphoBloc>().add(const YieldDataRequested())
                      : null,
                );
              }

              if (!data.hasPosition) {
                return _tile(
                  subtitle: data.apy == null
                      ? null
                      : (style) => Text(morphoApyText(context, data.apy!), style: style),
                  trailing: (style) => Text(S.of(context).setup, style: style),
                  onTap: () => _open(
                    context,
                    MorphoIntroPage(authService: getIt.get<AuthService>()),
                  ),
                );
              }

              final earned = data.earned;
              final amountFiat = fiatRate?.convert(data.positionValue);

              return _tile(
                subtitle: (style) => MoneyText(data.positionValue, style: style),
                trailing: (style) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (amountFiat != null)
                      MoneyText(amountFiat, fractionalDigits: 2, trimZeros: false, style: style),
                    if (earned != null) DefiEarnedText(earned, fiatRate: fiatRate, style: style),
                  ],
                ),
                onTap: () => _open(
                  context,
                  MorphoPositionPage(authService: getIt.get<AuthService>()),
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
        logo: const DefiProviderLogo("assets/new-ui/morpho_logo.svg"),
        name: "Morpho",
        trailing: trailing,
        subtitle: subtitle,
        onTap: onTap,
      );

  Future<void> _open(BuildContext context, Widget rootPage) async {
    final bloc = context.read<MorphoBloc>();
    final fiatRate = context.read<FiatRateCubit>();
    bloc.add(const YieldDataRequested());

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

    if (!bloc.isClosed && settled is! MorphoReady) {
      bloc.add(const YieldDataRequested());
    }
  }
}
