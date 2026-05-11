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
      padding: EdgeInsets.only(
          bottom: 10, left: 18, right: 18, top: 10 + _additionalTopPadding(context)),
      child: Observer(
        builder: (_) {
          final syncBar = SyncBar(
            dashboardViewModel: dashboardViewModel,
            isSyncHeavy: dashboardViewModel.isSyncHeavy,
          );
          final shouldUseColumn = syncBar.showFullBar;

          final chainIcon = ChainIcon(
            iconPath: getCryptoCurrencyIconForWalletListItem(dashboardViewModel.wallet.type),
            dashboardViewModel: dashboardViewModel,
            isSyncHeavy: dashboardViewModel.isSyncHeavy,
            openChainSelection: openChainSelection,
          );

          final walletInfoBar = WalletInfoBar(
            hardwareWalletType: dashboardViewModel.wallet.hardwareWalletType,
            name: truncatedWalletName,
            hasCustomize: hasCustomize,
            onCustomizeButtonTap: openAccountCustomizer,
          );

          final settingsButton = ModernButton.svg(
            iconColor: Theme.of(context).colorScheme.primary,
            size: 36,
            onPressed: () {
              HapticFeedback.mediumImpact();
              onSettingsButtonPress();
            },
            svgPath: "assets/new-ui/top-settings.svg",
          );

          if (shouldUseColumn) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: shouldUseColumn
                    ? Column(
                        key: const ValueKey('column_layout'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              chainIcon,
                              const Spacer(),
                              syncBar,
                              const Spacer(),
                              settingsButton,
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const SizedBox(width: 58),
                              Expanded(
                                child: Center(child: walletInfoBar),
                              ),
                              const SizedBox(width: 36),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('row_layout'),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          chainIcon,
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              walletInfoBar,
                              const SizedBox(width: 12),
                              syncBar,
                            ],
                          ),
                          const Spacer(),
                          settingsButton,
                        ],
                      ),
              ),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              chainIcon,
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  walletInfoBar,
                  const SizedBox(width: 12),
                  syncBar,
                ],
              ),
              const Spacer(),
              settingsButton,
            ],
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
