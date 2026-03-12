import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Observer(
        builder: (_) => Row(
          spacing: 12,
          children: [
            (dashboardViewModel.hasLightning)
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
              iconColor: Theme.of(context).colorScheme.primary,
              size: 36,
              onPressed: () {
                HapticFeedback.mediumImpact();
                onSettingsButtonPress();
              },
              svgPath: "assets/new-ui/top-settings.svg",
            ),
          ],
        ),
      ),
    );
  }
}
