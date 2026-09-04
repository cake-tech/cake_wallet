import "dart:async";
import "dart:io";

import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/wallet_info_bar.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/sync_status.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";

class TopBar extends StatefulWidget {
  const TopBar({
    required this.dashboardViewModel,
    required this.onSettingsButtonPress,
    required this.openChainSelection,
    required this.lightningMode,
    required this.onLightningSwitchPress,
    super.key,
  });

  static const Duration _transitionDuration = Duration(milliseconds: 350);

  final VoidCallback onSettingsButtonPress;
  final VoidCallback openChainSelection;
  final DashboardViewModel dashboardViewModel;
  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  static const syncedMessageDuration = Duration(seconds: 3);

  bool showSyncedMessage = false;
  Timer? syncedMessageTimer;
  late final ReactionDisposer? _statusReactionDisposer;

  @override
  void initState() {
    super.initState();

    _statusReactionDisposer = reaction(
          (_) => widget.dashboardViewModel.status.runtimeType,
          (status) {
        syncedMessageTimer?.cancel();

        if (!mounted) return;

        if (status == SyncedSyncStatus) {
          setState(() => showSyncedMessage = true);
          syncedMessageTimer = Timer(syncedMessageDuration, () {
            if (mounted) setState(() => showSyncedMessage = false);
          });
        } else {
          setState(() => showSyncedMessage = false);
        }
      },
    );
  }

  @override
  void dispose() {
    syncedMessageTimer?.cancel();
    _statusReactionDisposer?.reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: 10,
      left: 18,
      right: 18,
      top: 10 + _additionalTopPadding(context),
    ),
    child: Observer(
      builder: (_) {
        final dashboardViewModel = widget.dashboardViewModel;

        final syncBar = SyncBar(
          dashboardViewModel: dashboardViewModel,
          isSyncHeavy: dashboardViewModel.isSyncHeavy,
          showSyncedMessage: showSyncedMessage,
        );

        final compactSyncBar = SyncBar(
          dashboardViewModel: dashboardViewModel,
          isSyncHeavy: dashboardViewModel.isSyncHeavy,
          showSyncedMessage: showSyncedMessage,
          forceCompact: true,
        );

        final isHeavySyncing = syncBar.showFullBar;

        final Widget leading = ChainIcon(
          iconPath: getCryptoCurrencyIconForWalletListItem(dashboardViewModel.wallet.type),
          dashboardViewModel: dashboardViewModel,
          isSyncHeavy: dashboardViewModel.isSyncHeavy,
          showSyncedMessage: showSyncedMessage,
          openChainSelection: widget.openChainSelection,
        );

        final walletInfoBar = WalletInfoBar(
          hardwareWalletType: dashboardViewModel.wallet.hardwareWalletType,
          walletIcon: dashboardViewModel.getGroupIcon(dashboardViewModel.wallet.walletInfo),
          groupName: dashboardViewModel.getGroupName(dashboardViewModel.wallet.walletInfo) ?? ""
        );

        final settingsButton = ModernButton.svg(
          iconColor: Theme.of(context).colorScheme.primary,
          size: 36,
          onPressed: () {
            HapticFeedback.mediumImpact();
            widget.onSettingsButtonPress();
          },
          svgPath: "assets/new-ui/top-settings.svg",
          semanticLabel: S.of(context).settings_title,
        );

        return AnimatedSize(
          duration: TopBar._transitionDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Row(
            children: [
              leading,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedSize(
                    duration: TopBar._transitionDuration,
                    curve: Curves.easeInOut,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedOpacity(
                          duration: TopBar._transitionDuration,
                          curve: Curves.easeInOut,
                          opacity: isHeavySyncing ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: isHeavySyncing,
                            child: ExcludeSemantics(
                              excluding: isHeavySyncing,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(child: walletInfoBar),
                                  const SizedBox(width: 12),
                                  compactSyncBar,
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: TopBar._transitionDuration,
                          curve: Curves.easeInOut,
                          opacity: isHeavySyncing ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !isHeavySyncing,
                            child: ExcludeSemantics(
                              excluding: !isHeavySyncing,
                              child: syncBar,
                            ),
                          ),
                        ),
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

  //FIXME remove after this gets fixed flutter-side
  double _additionalTopPadding(BuildContext context) {
    if (Platform.isIOS && MediaQuery.of(context).viewPadding.top < 12) return 24;

    return 0;
  }
}