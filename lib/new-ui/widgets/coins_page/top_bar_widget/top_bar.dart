import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart';
import "package:cake_wallet/new-ui/widgets/coins_page/wallet_info.dart";
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class TopBar extends StatefulWidget {
  const TopBar({
    required this.lightningMode,
    required this.onLightningSwitchPress,
    required this.dashboardViewModel,
    required this.onSettingsButtonPress,
    super.key,
  });

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;
  final VoidCallback onSettingsButtonPress;
  final DashboardViewModel dashboardViewModel;

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  static const syncedMessageDuration = Duration(seconds: 3);

  bool showSyncedMessage = false;
  Timer? syncedMessageTimer;
  ReactionDisposer? _statusReactionDisposer;

  @override
  void initState() {
    super.initState();
    _bindStatusReaction();
  }

  @override
  void didUpdateWidget(covariant TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (identical(oldWidget.dashboardViewModel, widget.dashboardViewModel)) {
      return;
    }

    syncedMessageTimer?.cancel();
    syncedMessageTimer = null;
    showSyncedMessage = false;
    _statusReactionDisposer?.call();
    _bindStatusReaction();
  }

  void _bindStatusReaction() {
    _statusReactionDisposer = reaction(
      (_) => widget.dashboardViewModel.status.runtimeType,
      (status) {
        syncedMessageTimer?.cancel();
        syncedMessageTimer = null;

        if (status == SyncedSyncStatus) {
          if (mounted) {
            setState(() => showSyncedMessage = true);
          }
          syncedMessageTimer = Timer(syncedMessageDuration, () {
            syncedMessageTimer = null;
            if (mounted) {
              setState(() => showSyncedMessage = false);
            }
          });
        } else {
          if (mounted) {
            setState(() => showSyncedMessage = false);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    syncedMessageTimer?.cancel();
    syncedMessageTimer = null;
    _statusReactionDisposer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 10 + _additionalTopPadding(context)),
        child: Observer(
          builder: (_) {
            final syncBar = SyncBar(
              dashboardViewModel: widget.dashboardViewModel,
              isSyncHeavy: widget.dashboardViewModel.isSyncHeavy,
              showSyncedMessage: showSyncedMessage,
            );
            final replacesWalletName = syncBar.replacesWalletName;
            final hasLightning = widget.dashboardViewModel.hasLightning;
            final leading = hasLightning
                ? LightningSwitcher(
                    lightningMode: widget.lightningMode,
                    onLightningSwitchPress: widget.onLightningSwitchPress,
                  )
                : ChainIcon(
                    iconPath: widget.dashboardViewModel.wallet.currency.flatIconPath ?? "",
                    dashboardViewModel: widget.dashboardViewModel,
                    isSyncHeavy: widget.dashboardViewModel.isSyncHeavy,
                    showSyncedMessage: showSyncedMessage,
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

            if (hasLightning && widget.dashboardViewModel.isSyncHeavy && replacesWalletName) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Flexible(
                    child: SizedBox(
                      width: 210,
                      height: 36,
                      child: syncBar,
                    ),
                  ),
                  const SizedBox(width: 12),
                  settingsButton,
                ],
              );
            }

            return Row(
              spacing: 12,
              children: [
                leading,
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: replacesWalletName
                        ? syncBar
                        : Row(
                            children: [
                              Expanded(
                                child: WalletInfoBar(
                                  name: widget.dashboardViewModel.wallet.name,
                                  hardwareWalletType:
                                      widget.dashboardViewModel.wallet.hardwareWalletType,
                                ),
                              ),
                              if (syncBar.hasCompactContent) ...[
                                const SizedBox(width: 6),
                                syncBar,
                              ],
                            ],
                          ),
                  ),
                ),
                if (hasLightning && !replacesWalletName)
                  SizedBox(
                    width: 63,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: settingsButton,
                    ),
                  )
                else
                  settingsButton,
              ],
            );
          },
        ),
      );

  //FIXME remove after this gets fixed flutter-side
  double _additionalTopPadding(BuildContext context) {
    if (Platform.isIOS && MediaQuery.of(context).viewPadding.top < 12) {
      return 24;
    }

    return 0;
  }
}
