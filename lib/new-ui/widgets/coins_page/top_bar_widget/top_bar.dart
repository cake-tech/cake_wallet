import "dart:io";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/wallet_info_bar.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class TopBar extends StatelessWidget {
  const TopBar({
    required this.dashboardViewModel,
    required this.onSettingsButtonPress,
    required this.openChainSelection,
    super.key,
  });

  static const Duration _transitionDuration = Duration(milliseconds: 350);

  final VoidCallback onSettingsButtonPress;
  final VoidCallback openChainSelection;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    final walletNameToDisplay = dashboardViewModel.wallet.name.split("_")[0];
    final truncatedWalletName = walletNameToDisplay.length > 25
        ? "${walletNameToDisplay.substring(0, 20)}..."
        : walletNameToDisplay;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: 18,
        right: 18,
        top: 10 + _additionalTopPadding(context),
      ),
      child: Observer(
        builder: (_) {
          final syncBar = SyncBar(
            dashboardViewModel: dashboardViewModel,
            isSyncHeavy: dashboardViewModel.isSyncHeavy,
          );

          final isSyncing = syncBar.showFullBar;

          final chainIcon = ChainIcon(
            iconPath: getCryptoCurrencyIconForWalletListItem(dashboardViewModel.wallet.type),
            dashboardViewModel: dashboardViewModel,
            isSyncHeavy: dashboardViewModel.isSyncHeavy,
            openChainSelection: openChainSelection,
          );

          final walletInfoBar = WalletInfoBar(
            hardwareWalletType: dashboardViewModel.wallet.hardwareWalletType,
            name: truncatedWalletName,
          );

          final settingsButton = ModernButton.svg(
            iconColor: Theme.of(context).colorScheme.primary,
            size: 36,
            onPressed: () {
              HapticFeedback.mediumImpact();
              onSettingsButtonPress();
            },
            svgPath: "assets/new-ui/top-settings.svg",
            semanticLabel: S.of(context).settings_title,
          );

          return AnimatedSize(
            duration: _transitionDuration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                chainIcon,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AnimatedSwitcher(
                      duration: _transitionDuration,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: isSyncing
                          ? KeyedSubtree(
                        key: const ValueKey("sync_bar_only"),
                        child: syncBar,
                      )
                          : Row(
                        key: const ValueKey("wallet_info_bar"),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(child: walletInfoBar),
                          const SizedBox(width: 12),
                          syncBar,
                        ],
                      ),
                    ),
                  ),
                ),
                settingsButton,
              ],
            ),
          );
        },
      ),
    );
  }

  //FIXME remove after this gets fixed flutter-side
  double _additionalTopPadding(BuildContext context) {
    if (Platform.isIOS && MediaQuery.of(context).viewPadding.top < 12) return 24;

    return 0;
  }
}