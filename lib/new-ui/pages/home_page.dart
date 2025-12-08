import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/pages/card_customizer.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/action_row/coin_action_row.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_section.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/lightning_assets.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/cards/cards_view.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class NewHomePage extends StatefulWidget {
  NewHomePage({super.key, required this.dashboardViewModel}) {
    this.accountListViewModel = dashboardViewModel.balanceViewModel.hasAccounts
        ? getIt.get<MoneroAccountListViewModel>()
        : null;
  }

  final DashboardViewModel dashboardViewModel;
  late final MoneroAccountListViewModel? accountListViewModel;

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  bool _lightningMode = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CardCustomizerBloc, CardCustomizerState>(
      listener: (context, state) async {
        if (state is CardCustomizerSaved) {
          widget.dashboardViewModel.loadCardDesigns();
        }
      },
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceBright,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
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
                ),
                WalletInfo(
                  lightningMode: _lightningMode,
                  usesHardwareWallet: widget.dashboardViewModel.wallet.isHardwareWallet,
                  name: widget.dashboardViewModel.wallet.name,
                  onCustomizeButtonTap: () {
                    final bloc = context.read<CardCustomizerBloc>();
                    showCupertinoModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Material(
                            child: BlocProvider.value(
                              value: bloc,
                              child: CardCustomizer(
                                cryptoTitle: widget.dashboardViewModel.wallet.currency.fullName ??
                                    widget.dashboardViewModel.wallet.currency.name,
                                cryptoName: widget.dashboardViewModel.wallet.currency.name,
                              ),
                            ),
                          );
                        });
                  },
                ),
                CardsView(
                  dashboardViewModel: widget.dashboardViewModel,
                  accountListViewModel: widget.accountListViewModel,
                  lightningMode: _lightningMode,
                ),
                CoinActionRow(lightningMode: _lightningMode),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _lightningMode
                      ? LightningAssets(
                          dashboardViewModel: widget.dashboardViewModel,
                        )
                      : HistorySection(
                          dashboardViewModel: widget.dashboardViewModel,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
