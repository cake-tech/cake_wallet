import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/swap/bloc/swap_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_mobx/flutter_mobx.dart";

CurrencyPickerArgs walletAssetsPickerArgs(
  SwapBloc bloc,
  CryptoCurrency selected, {
  CurrencyPickerArgs? otherAssets,
}) => CurrencyPickerArgs(
  items: bloc.wallet.balance.keys.toList(),
  selected: selected,
  filterByNetwork: cryptoCurrencyOrTokenToWalletType(bloc.wallet.currency) ?? bloc.wallet.type,
  balanceByAsset: {
    for (final MapEntry(:key, :value) in bloc.wallet.balance.entries)
      key: CurrencyPickerBalance(amount: value.available.toStringWithSymbol()),
  },
  useSingleNetworkLayout: true,
  walletName: bloc.wallet.name,
  otherAssets: otherAssets,
  onSelected: (currency) => bloc.add(DepositCurrencyChanged(currency)),
  symbolResolver: (curr) => curr.symbol,
);

class SwapSourceSelector extends StatelessWidget {
  const SwapSourceSelector({required this.bloc, super.key});

  // final String currencyIconPath;
  // final String currencyLabel;
  // final String availableBalance;
  // final VoidCallback onTap;
  // final String? chainIconPath;
  // final String? walletName;

  final SwapBloc bloc;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<SwapBloc, SwapState>(
      bloc: bloc,
      builder: (context, state) {
        if (state is! SwapStateWithInputs) {
          return const SizedBox.shrink();
        }
        return Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _presentCurrencyPicker(context),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    TokenImageWidget(
                      imageUrl: state.depositAmount.currency.iconPath ?? "",
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.depositAmount.currency.fullName ?? state.depositAmount.currency.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: -0.08),
                    ),
                    if (state.depositAmount.currency.chainIconPath != null &&
                        state.depositAmount.currency.chainIconPath!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      CakeImageWidget(
                        imageUrl: state.depositAmount.currency.chainIconPath!,
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                      ),
                    ],
                    const Spacer(),
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/chooser.svg",
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CakeImageWidget(
                          imageUrl: "assets/new-ui/wallet_filled.svg",
                          width: 16,
                          height: 16,
                          colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            state.source.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.06,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Observer(
                    builder: (_) => Text(
                      S
                          .of(context)
                          .available_balance_short(bloc.spendingBalance.toStringWithSymbol()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.06,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _presentCurrencyPicker(BuildContext context) {
    if (bloc.state case final SwapStateWithInputs s when bloc.wallet.balance.length > 1) {
      CurrencyPickerSheet.show(
        context: context,
        args: walletAssetsPickerArgs(bloc, s.depositAmount.currency),
      );
    }
  }
}
