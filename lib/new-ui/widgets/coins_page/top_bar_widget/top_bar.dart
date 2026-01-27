import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.lightningMode,
    required this.onLightningSwitchPress,
    required this.dashboardViewModel,
    required this.onSettingsButtonPress,
  });

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;
  final VoidCallback onSettingsButtonPress;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 10.0),
      child: Observer(
        builder: (_) => Row(
          spacing: 12,
          children: [
            (dashboardViewModel.balanceViewModel.hasSecondAdditionalBalance ||
                    dashboardViewModel.balanceViewModel.hasSecondAvailableBalance)
                ? LightningSwitcher(
                    lightningMode: lightningMode,
                    onLightningSwitchPress: onLightningSwitchPress,
                  )
                : ChainIcon(
                    iconPath: dashboardViewModel.wallet.currency.flatIconPath ?? "",
                    dashboardViewModel: dashboardViewModel,
                    isSyncHeavy: dashboardViewModel.isSyncHeavy),
            SyncBar(
              dashboardViewModel: dashboardViewModel,
              isSyncHeavy: dashboardViewModel.isSyncHeavy,
            ),
            ModernButton.svg(
              size: 44,
              onPressed: onSettingsButtonPress,
              svgPath: "assets/new-ui/top-settings.svg",
            ),
          ],
        ),
      ),
    );
  }
}