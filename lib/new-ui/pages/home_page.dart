import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/pages/account_customizer.dart';
import 'package:cake_wallet/new-ui/pages/card_customizer.dart';
import 'package:cake_wallet/new-ui/pages/settings_page.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/action_row/coin_action_row.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_history_section.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/cards_view.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/unconfirmed_balance_widget.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_edit_or_create_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
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
  MoneroAccountListViewModel? accountListViewModel;
  bool _lightningMode = false;

  @override
  void initState() {
    super.initState();
    _setAccountViewModel();
    reaction((_)=>widget.dashboardViewModel.wallet, (_)=>_setAccountViewModel());
  }

  void _setAccountViewModel() {
    accountListViewModel = widget.dashboardViewModel.balanceViewModel.hasAccounts
        ? getIt.get<MoneroAccountListViewModel>()
        : null;
  }

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
          slivers:[
            SliverPadding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              sliver: CupertinoSliverRefreshControl(
                onRefresh: () => widget.dashboardViewModel.refreshDashboard(),
              ),
            ),
            SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 24.0,
              children: [
                TopBar(
                  dashboardViewModel: widget.dashboardViewModel,
                  lightningMode: _lightningMode,
                  onLightningSwitchPress: () {
                    setState(() {
                      _lightningMode = !_lightningMode;
                    });
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
                          ))),
                    );
                  },
                ),
                WalletInfo(
                  lightningMode: _lightningMode,
                  hardwareWalletType: widget.dashboardViewModel.wallet.hardwareWalletType,
                  name: widget.dashboardViewModel.wallet.name,
                  onCustomizeButtonTap: openCustomizer
                ),
                Column(
                  children: [
                    CardsView(
                      key: ValueKey(widget.dashboardViewModel.wallet.name),
                      dashboardViewModel: widget.dashboardViewModel,
                      accountListViewModel: accountListViewModel,
                      onCompactModeBackgroundCardsTapped: openCustomizer,
                      lightningMode: _lightningMode,
                    ),
                    UnconfirmedBalanceWidget(dashboardViewModel: widget.dashboardViewModel,),
                  ],
                ),
                Observer(
                  builder: (_) => CoinActionRow(
                    lightningMode: _lightningMode,
                    showSwap: widget.dashboardViewModel.isEnabledSwapAction,
                  ),
                ),
                Observer(
                  builder: (_) => AssetsHistorySection(
                    nftViewModel: widget.nftViewModel,
                    dashboardViewModel: widget.dashboardViewModel,
                  ),
                ),
                SizedBox(height: 80.0)
                ],
            ),
          ),]
        ),
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

  void openCustomizer() {
    CupertinoScaffold.showCupertinoModalBottomSheet(
      barrierColor: Colors.black.withAlpha(60),
      context: context,
      builder: (context) {
        final bloc = getIt.get<CardCustomizerBloc>(param1: _lightningMode);

        return ModalNavigator(
          parentContext: context,
          heightMode: ModalHeightModes.fullScreen,
          rootPage: BlocProvider(
            create: (context) => bloc,
            child: Material(
              child: BlocListener<CardCustomizerBloc, CardCustomizerState>(
                listener: (context, state) {
                  if (state is CardCustomizerSaved) {
                    widget.dashboardViewModel.loadCardDesigns();
                  }
                },
                child: accountListViewModel == null
                    ? CardCustomizer(
                  cryptoTitle: widget.dashboardViewModel.wallet.currency.fullName ??
                      widget.dashboardViewModel.wallet.currency.name,
                  cryptoName: widget.dashboardViewModel.wallet.currency.name,
                )
                    : AccountCustomizer(
                  accountListViewModel: accountListViewModel!,
                  accountEditOrCreateViewModel:
                  getIt.get<MoneroAccountEditOrCreateViewModel>(),
                  dashboardViewModel: widget.dashboardViewModel,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
