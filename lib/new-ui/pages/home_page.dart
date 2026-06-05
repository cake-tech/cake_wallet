import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/card_customizer.dart';
import 'package:cake_wallet/new-ui/pages/settings_page.dart';
import 'package:cake_wallet/new-ui/utils/show_card_customizer.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/action_row/coin_action_row.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_history_section.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/cards_view.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/mweb_ad.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/unconfirmed_balance_widget.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class NewHomePage extends StatefulWidget {
  NewHomePage({super.key, required this.dashboardViewModel, required this.nftViewModel});

  final DashboardViewModel dashboardViewModel;
  final NFTViewModel nftViewModel;

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceDim,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          CustomScrollView(
              physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  sliver: CupertinoSliverRefreshControl(
                    refreshTriggerPullDistance: 160,
                    refreshIndicatorExtent: 90,
                    onRefresh: () => widget.dashboardViewModel.refreshDashboard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Observer(
                    builder: (_) {
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        spacing: 24.0,
                        children: [
                          TopBar(
                            dashboardViewModel: widget.dashboardViewModel,
                            onLightningSwitchPress: () {
                                widget.dashboardViewModel.toggleLightningMode();
                            },
                            onSettingsButtonPress: () {
                              CupertinoScaffold.showCupertinoModalBottomSheet(
                                context: context,
                                barrierColor: Colors.black.withAlpha(85),
                                builder: (context) => FractionallySizedBox(
                                  child: Material(
                                    child: NewSettingsPage(
                                      dashboardViewModel: widget.dashboardViewModel,
                                      authService: getIt.get<AuthService>(),
                                    ),
                                  ),
                                ),
                              ).then((_) async {
                                await widget.dashboardViewModel.loadCardDesigns();
                                setState(() {});
                              });
                            },
                          ),
                          WalletInfoBar(
                              hardwareWalletType:
                                  widget.dashboardViewModel.wallet.hardwareWalletType,
                              name: widget.dashboardViewModel.wallet.name),
                          Column(
                            children: [
                              CardsView(
                                key: ValueKey(widget.dashboardViewModel.wallet.name),
                                onCustomizeTapped: openCardCustomizer,
                                dashboardViewModel: widget.dashboardViewModel,
                                accountListViewModel:
                                    widget.dashboardViewModel.accountListViewModel,
                                onCompactModeBackgroundCardsTapped: openCardCustomizer,
                                lightningMode: widget.dashboardViewModel.lightningMode,
                              ),
                              Observer(builder: (_) {
                                return AnimatedSize(
                                  duration: Duration(milliseconds: 150),
                                  curve: Curves.easeInOutCubic,
                                  child: (widget.dashboardViewModel.shouldShowBalanceHiddenMessage)
                                      ? Column(
                                          children: [
                                            SizedBox(
                                              height: 12,
                                              width: double.infinity,
                                            ),
                                            Text(
                                              S.of(context).long_press_show_balance,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant),
                                            )
                                          ],
                                        )
                                      : SizedBox(width: double.infinity),
                                );
                              }),
                              UnconfirmedBalanceWidget(
                                  dashboardViewModel: widget.dashboardViewModel),
                            ],
                          ),
                          Column(
                            children: [
                              CoinActionRow(
                                lightningMode: widget.dashboardViewModel.lightningMode,
                                showSwap: widget.dashboardViewModel.isEnabledSwapAction,
                                walletType: widget.dashboardViewModel.wallet.type,
                              ),
                              MwebAd(
                                dashboardViewModel: widget.dashboardViewModel,
                              ),
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ),
                Observer(
                  builder: (_) => AssetsHistorySection(
                    nftViewModel: widget.nftViewModel,
                    dashboardViewModel: widget.dashboardViewModel,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 80.0),
                )
              ]),
          Container(
            height: (MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  Theme.of(context).colorScheme.surface.withAlpha(5),
                  Theme.of(context).colorScheme.surface.withAlpha(25),
                  Theme.of(context).colorScheme.surface.withAlpha(50),
                  Theme.of(context).colorScheme.surface.withAlpha(100),
                  Theme.of(context).colorScheme.surface.withAlpha(150),
                  Theme.of(context).colorScheme.surface.withAlpha(175),
                  Theme.of(context).colorScheme.surface.withAlpha(200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openCardCustomizer() async {
    await showCardCustomizer(
      context: context,
      dashboardViewModel: widget.dashboardViewModel,
      lightningMode: widget.dashboardViewModel.lightningMode,
    );
  }
}
