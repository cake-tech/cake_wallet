import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_amount_page.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_earned_text.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/morpho/morpho_rows.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MorphoWithdrawAssetsPage extends StatelessWidget {
  const MorphoWithdrawAssetsPage({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => BlocBuilder<MorphoBloc, MorphoState>(
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final data = state.data!;
            final earned = data.earned;
            final amountFiat = fiatRate?.convert(data.positionValue);
            final colorScheme = Theme.of(context).colorScheme;
            final style = TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant);

            return DefiScaffold(
              child: Column(
                children: [
                  ModalTopBar(
                    title: S.of(context).withdraw_assets,
                    leadingIcon: const Icon(Icons.close),
                    leadingSemanticLabel: S.of(context).close,
                    onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      child: NewListSections(
                        showHeader: true,
                        sections: {
                          S.of(context).deposited_on("Morpho"): [
                            morphoUsdcRow(
                              trailingWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 8,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      MoneyText(
                                        amountFiat ?? data.positionValue,
                                        fractionalDigits: amountFiat == null ? 8 : 2,
                                        trimZeros: amountFiat == null,
                                        style: style,
                                      ),
                                      if (earned != null)
                                        DefiEarnedText(earned, fiatRate: fiatRate, style: style),
                                    ],
                                  ),
                                  CakeImageWidget(
                                    imageUrl: "assets/new-ui/arrow_forward.svg",
                                    height: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  builder: (_) => Material(
                                    color: Colors.transparent,
                                    child: MorphoAmountPage(
                                      mode: MorphoAmountMode.withdraw,
                                      authService: authService,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
