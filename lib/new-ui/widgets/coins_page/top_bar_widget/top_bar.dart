import 'dart:io';

import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.dashboardViewModel,
    required this.onSettingsButtonPress,
    required this.openAccountCustomizer,
    required this.openChainSelection,
    required this.hasCustomize,
  });

  final VoidCallback onSettingsButtonPress;
  final VoidCallback openAccountCustomizer;
  final VoidCallback openChainSelection;
  final DashboardViewModel dashboardViewModel;
  final bool hasCustomize;

  @override
  Widget build(BuildContext context) {
    final walletNameToDisplay = dashboardViewModel.wallet.name.split('_')[0];
    final truncatedWalletName = walletNameToDisplay.length > 20
        ? '${walletNameToDisplay.substring(0, 17)}...'
        : walletNameToDisplay;
    return Padding(
      padding: EdgeInsets.only(bottom: 10, left: 18, right:18, top: 10+_additionalTopPadding(context)),
      child: Observer(
        builder: (_) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ChainIcon(
                    iconPath: getCryptoCurrencyIconForWalletListItem(dashboardViewModel.wallet.type),
                    dashboardViewModel: dashboardViewModel,
                    isSyncHeavy: dashboardViewModel.isSyncHeavy,
                    openChainSelection: openChainSelection),
            Spacer(),
            WalletInfoBar(
                hardwareWalletType: dashboardViewModel.wallet.hardwareWalletType,
                name: truncatedWalletName,
                hasCustomize: hasCustomize,
                onCustomizeButtonTap: openAccountCustomizer),
            SizedBox(width: 12),
            SyncBar(
              dashboardViewModel: dashboardViewModel,
              isSyncHeavy: dashboardViewModel.isSyncHeavy,
            ),
            Spacer(),
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


  //FIXME remove after this gets fixed flutter-side
  double _additionalTopPadding(BuildContext context) {
    if(Platform.isIOS && MediaQuery.of(context).viewPadding.top < 12) return 24;

    return 0;
  }
}
