import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_select_asset_page.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_withdraw_assets_page.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_yield_by_asset_sheet.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_position_view.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_provider_logo.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_badge.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_rows.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MorphoPositionPage extends StatelessWidget {
  const MorphoPositionPage({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => BlocBuilder<MorphoBloc, MorphoState>(
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final data = state.data!;
            final earned = data.earned;
            final theme = Theme.of(context);

            return DefiPositionView(
              name: "Morpho",
              logo: const DefiProviderLogo("assets/new-ui/morpho_logo.svg"),
              amount: data.positionValue,
              fiatRate: fiatRate,
              showSectionHeaders: true,
              sections: {
                "": [
                  morphoProviderRow(context),
                  morphoVariableYieldRow(
                    context,
                    onTap: () => MorphoYieldByAssetSheet.show(context: context, apy: data.apy),
                  ),
                  if (earned != null) morphoTotalEarnedRow(context, earned, fiatRate),
                ],
                S.of(context).deposited: [
                  morphoUsdcRow(
                    trailingWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          data.positionValue,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (data.apy != null)
                          Text(
                            morphoApyText(context, data.apy!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (earned != null) morphoUsdcEarnedRow(context, earned, fiatRate),
                ],
              },
              onWithdraw: data.positionValue.isZero
                  ? null
                  : () => _push(context, MorphoWithdrawAssetsPage(authService: authService)),
              onDeposit: () => _push(context, MorphoSelectAssetPage(authService: authService)),
              attribution: const MorphoBadge(),
            );
          },
        ),
      );

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => Material(color: Colors.transparent, child: page),
        ),
      );
}
