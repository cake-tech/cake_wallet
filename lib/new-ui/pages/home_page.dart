import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/omnichain_change_network_page.dart";
import "package:cake_wallet/new-ui/pages/send_page.dart";
import "package:cake_wallet/new-ui/pages/settings_page.dart";
import "package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart";
import "package:cake_wallet/new-ui/utils/show_card_customizer.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/action_row/coin_action_row.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_history_section.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/cards_view.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/mweb_ad.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/top_bar.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/unconfirmed_balance_widget.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/utils/feature_flag.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cake_wallet/view_model/dashboard/nft_view_model.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class NewHomePage extends StatefulWidget {
  const NewHomePage({required this.dashboardViewModel, required this.nftViewModel, super.key});

  final DashboardViewModel dashboardViewModel;
  final NFTViewModel nftViewModel;

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  @override
  Widget build(BuildContext context) {
    final dashboardVM = widget.dashboardViewModel;
    final nftVM = widget.nftViewModel;

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
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  sliver: CupertinoSliverRefreshControl(
                    refreshTriggerPullDistance: 160,
                    refreshIndicatorExtent: 90,
                    onRefresh: dashboardVM.refreshDashboard,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 24,
                    children: [
                      TopBar(
                        dashboardViewModel: dashboardVM,
                        onSettingsButtonPress: () {
                          CupertinoScaffold.showCupertinoModalBottomSheet(
                            context: context,
                            barrierColor: Colors.black.withAlpha(85),
                            builder: (context) => FractionallySizedBox(
                                child: Material(
                                    child: NewSettingsPage(
                              dashboardViewModel: dashboardVM,
                              authService: getIt.get<AuthService>(),
                            ))),
                          );
                        },
                        openChainSelection: () {
                          CupertinoScaffold.showCupertinoModalBottomSheet(
                            context: context,
                            barrierColor: Colors.black.withAlpha(85),
                            builder: (context) => FractionallySizedBox(
                              child: Material(
                                child: OmniChainChangeNetworkPage(
                                  omniChainWalletCreationService:
                                      getIt.get<OmniChainWalletCreationService>(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (dashboardVM.hasLightning)
                        LightningSwitcher(
                          lightningMode: dashboardVM.lightningMode,
                          onLightningSwitchPress: () {
                            setState(() {
                              dashboardVM.lightningMode = !dashboardVM.lightningMode;
                            });
                          },
                        ),
                      Column(
                        children: [
                          Observer(
                            builder: (_) => CardsView(
                                key: ValueKey(dashboardVM.wallet.name),
                                onCustomizeTapped: openCardCustomizer,
                                dashboardViewModel: dashboardVM,
                                onCompactModeBackgroundCardsTapped: openCardCustomizer,
                                lightningMode: dashboardVM.lightningMode,
                                actions: dashboardVM.lightningMode
                                    ? [
                                        BalanceCardAction(
                                          label: S.current.bitcoin_lightning_deposit,
                                          icon: Icons.arrow_downward,
                                          onTap: depositToL2,
                                        ),
                                        BalanceCardAction(
                                          label: S.current.bitcoin_lightning_withdraw,
                                          icon: Icons.arrow_upward,
                                          onTap: withdrawFromL2,
                                        )
                                      ]
                                    : widget.dashboardViewModel.isEnabledTradeAction
                                        ? [
                                            BalanceCardAction(
                                              label: S.current.buy,
                                              icon: Icons.arrow_forward_ios_rounded,
                                              iconSize: 12,
                                              onTap: () => Navigator.of(context)
                                                  .pushNamed(Routes.buySellPage),
                                            )
                                          ]
                                        : []),
                          ),
                          Observer(
                              builder: (_) => AnimatedSize(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeInOutCubic,
                                    child: (dashboardVM.shouldShowBalanceHiddenMessage)
                                        ? Column(
                                            children: [
                                              const SizedBox(
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
                                        : const SizedBox(width: double.infinity),
                                  )),
                          UnconfirmedBalanceWidget(
                            dashboardViewModel: dashboardVM,
                          ),
                        ],
                      ),
                      Observer(
                        builder: (_) => Column(
                          children: [
                            CoinActionRow(
                              lightningMode: dashboardVM.lightningMode,
                              showSwap: dashboardVM.isEnabledSwapAction,
                              walletType: dashboardVM.wallet.type,
                            ),
                            MwebAd(
                              dashboardViewModel: dashboardVM,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Observer(
                  builder: (_) => AssetsHistorySection(
                    nftViewModel: nftVM,
                    dashboardViewModel: dashboardVM,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80.0),
                )
              ]),
          Container(
            height: MediaQuery.of(context).padding.top,
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

  Future<void> openCardCustomizer() async {
    final dashboardVM = widget.dashboardViewModel;
    await showCardCustomizer(
      context: context,
      dashboardViewModel: dashboardVM,
      lightningMode: dashboardVM.lightningMode,
    );
  }

  Future<void> depositToL2() async {
    final dashboardVM = widget.dashboardViewModel;
    PaymentRequest? paymentRequest;

    if (dashboardVM.type == WalletType.litecoin) {
      final depositAddress = bitcoin!.getUnusedMwebAddress(dashboardVM.wallet);
      if (depositAddress?.isNotEmpty ?? false) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("litecoin:$depositAddress"));
      }
    } else if (dashboardVM.type == WalletType.bitcoin) {
      final depositAddress = await bitcoin!.getUnusedSpakDepositAddress(dashboardVM.wallet);
      if (depositAddress?.isNotEmpty ?? false) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("bitcoin:$depositAddress"));
      }
    }

    if (FeatureFlag.hasNewUiExtraPages && dashboardVM.type == WalletType.bitcoin) {
      final page = getIt.get<NewSendPage>(
          param1: SendPageParams(
        initialPaymentRequest: paymentRequest,
        unspentCoinType: UnspentCoinType.nonMweb,
        mode: SendPageModes.lightningDeposit,
      ));
      await showCupertinoModalBottomSheet(
          context: context,
          barrierColor: Colors.black.withAlpha(128),
          builder: (context) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ModalNavigator(parentContext: context, rootPage: Material(child: page))),
              ));
    } else {
      Navigator.pushNamed(
        context,
        Routes.send,
        arguments: {
          'paymentRequest': paymentRequest,
          'coinTypeToSpendFrom': UnspentCoinType.nonMweb,
        },
      );
    }
  }

  Future<void> withdrawFromL2() async {
    final dashboardVM = widget.dashboardViewModel;
    PaymentRequest? paymentRequest;
    UnspentCoinType unspentCoinType = UnspentCoinType.any;
    final withdrawAddress = bitcoin!.getUnusedSegwitAddress(dashboardVM.wallet);

    if (dashboardVM.type == WalletType.litecoin) {
      if (withdrawAddress?.isNotEmpty ?? false) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("litecoin:$withdrawAddress"));
      }
      unspentCoinType = UnspentCoinType.mweb;
    } else if (dashboardVM.type == WalletType.bitcoin) {
      if (withdrawAddress?.isNotEmpty ?? false) {
        paymentRequest = PaymentRequest.fromUri(Uri.parse("bitcoin:$withdrawAddress"));
      }
      unspentCoinType = UnspentCoinType.lightning;
    }

    if (FeatureFlag.hasNewUiExtraPages && dashboardVM.type == WalletType.bitcoin) {
      final page = getIt.get<NewSendPage>(
          param1: SendPageParams(
        initialPaymentRequest: paymentRequest,
        unspentCoinType: unspentCoinType,
        mode: SendPageModes.lightningWithdrawal,
      ));
      await showCupertinoModalBottomSheet(
          context: context,
          barrierColor: Colors.black.withAlpha(128),
          builder: (context) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ModalNavigator(parentContext: context, rootPage: Material(child: page))),
              ));
    } else {
      Navigator.pushNamed(
        context,
        Routes.send,
        arguments: {
          'paymentRequest': paymentRequest,
          'coinTypeToSpendFrom': unspentCoinType,
        },
      );
    }
  }
}
