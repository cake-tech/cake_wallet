import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/morpho/morpho_amount_page.dart";
import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/viewmodels/morpho/morpho_bloc.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MorphoSelectAssetPage extends StatelessWidget {
  const MorphoSelectAssetPage({required this.authService, super.key});

  final AuthService authService;

  @override
  Widget build(BuildContext context) => BlocBuilder<MorphoBloc, MorphoState>(
        builder: (context, state) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
          builder: (context, fiatRate) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final balance = state.data!.walletBalance;
            final balanceFiat = fiatRate?.convert(balance);

            return DefiScaffold(
              child: Column(
                children: [
                  ModalTopBar(
                    title: S.of(context).select_asset_to_deposit,
                    leadingIcon: const Icon(Icons.close),
                    leadingSemanticLabel: S.of(context).close,
                    onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Text(
                              S.of(context).from,
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
                            ),
                            CakeImageWidget(
                              imageUrl: "assets/new-ui/wallet_filled.svg",
                              width: 16,
                              height: 16,
                              colorFilter:
                                  ColorFilter.mode(colorScheme.onSurfaceVariant, BlendMode.srcIn),
                            ),
                            Flexible(
                              child: Text(
                                context.read<MorphoBloc>().walletName,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CurrencyPickerListContainer(
                          rows: [
                            CurrencyPickerRow(
                              currency: MorphoVault.usdcToken,
                              isSelected: false,
                              chainBadgePath: CryptoCurrency.eth.chainIconPath,
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  MoneyText(
                                    balance,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (balanceFiat != null)
                                    MoneyText(
                                      balanceFiat,
                                      fractionalDigits: 2,
                                      trimZeros: false,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  builder: (_) => Material(
                                    color: Colors.transparent,
                                    child: MorphoAmountPage(
                                      mode: MorphoAmountMode.deposit,
                                      authService: authService,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
