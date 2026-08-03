import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
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
    required this.onLightningSwitchPress,
    required this.dashboardViewModel,
    required this.onSettingsButtonPress,
  });

  final VoidCallback onLightningSwitchPress;
  final VoidCallback onSettingsButtonPress;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: 10, left: 18, right: 18, top: 10 + _additionalTopPadding(context)),
      child: Observer(
        builder: (_) => Row(
          spacing: 12,
          children: [
            (dashboardViewModel.hasLightning)
                ? LightningSwitcher(
                    lightningMode: dashboardViewModel.lightningMode,
                    onLightningSwitchPress: onLightningSwitchPress,
                  )
                : ChainIcon(
                    iconPath: dashboardViewModel.wallet.currency.flatIconPath ?? "",
                    onProgress: dashboardViewModel.status.progress,
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
              semanticLabel: S.of(context).settings_title,
            ),
          ],
        ),
      ),
    );
  }

  //FIXME remove after this gets fixed flutter-side
  double _additionalTopPadding(BuildContext context) {
    if (Platform.isIOS && MediaQuery.of(context).viewPadding.top < 12) return 24;

    return 0;
  }
}
