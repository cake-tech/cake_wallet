import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/swap_page.dart";
import "package:cake_wallet/new-ui/viewmodels/charts/charts_bloc.dart";
import "package:cake_wallet/new-ui/widgets/charts_page/chart_header.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/action_row/coin_action_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/buy/buy_sell_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class ChartModal extends StatelessWidget {
  const ChartModal({required this.currency, required this.isFavorite, super.key});

  final CryptoCurrency currency;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt.get<ChartsBloc>()..add(Init()),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalTopBar(
                  title: "",
                  onLeadingPressed: Navigator.of(context).pop,
                  leadingIcon: const Icon(Icons.close),
                  padding: const EdgeInsets.only(top: 18, left: 18),
                ),
                ChartHeader(
                  currency: currency,
                  chartHeight: 220,
                  chartPadding: 32,
                  centered: true,
                  favorite: false,
                ),
                const SizedBox(
                  height: 48,
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: MediaQuery.of(context).size.width * 0.05,
                  children: [
                    CoinActionButton(
                      icon: CakeImageWidget(
                        imageUrl: "assets/new-ui/buy.svg",
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: S.of(context).buy,
                      action: () {
                        Navigator.of(context).pushNamed(
                          Routes.buySellPage,
                          arguments:
                              BuySellPageParams(startWithSell: false, initialCurrency: currency),
                        );
                      },
                    ),
                    CoinActionButton(
                      icon: CakeImageWidget(
                        imageUrl: "assets/new-ui/sell.svg",
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: S.of(context).sell,
                      action: () {
                        Navigator.of(context).pushNamed(
                          Routes.buySellPage,
                          arguments:
                              BuySellPageParams(startWithSell: true, initialCurrency: currency),
                        );
                      },
                    ),
                    CoinActionButton(
                      icon: CakeImageWidget(
                        imageUrl: "assets/new-ui/exchange.svg",
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: S.of(context).swap,
                      action: () {
                        final page = getIt.get<NewSwapPage>(param2: currency);
                        showCupertinoModalBottomSheet(
                          context: context,
                          barrierColor: Colors.black.withAlpha(85),
                          builder: (context) => Material(
                            child: ModalNavigator(
                              rootPage: page,
                              parentContext: context,
                            ),
                          ),
                        );
                      },
                    ),
                    CoinActionButton(
                      icon: CakeImageWidget(
                        width: 36,
                        height: 36,
                        imageUrl: "assets/new-ui/favorite.svg",
                        colorFilter: ColorFilter.mode(
                          isFavorite
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      gradientColors:
                          isFavorite ? [const Color(0xFFDF2626), const Color(0xFF980F0F)] : null,
                      label: S.of(context).favorite,
                      action: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                ),
                const SizedBox(
                  height: 32,
                ),
              ],
            ),
          ),
        ),
      );
}
