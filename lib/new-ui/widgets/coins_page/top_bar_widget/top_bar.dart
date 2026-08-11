import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/chain_icon.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/lightning_switcher.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/sync_bar.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class TopBar extends StatefulWidget {
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

        if (status == SyncedSyncStatus) {
          if(mounted) {
            setState(() => showSyncedMessage = true);
          }
          syncedMessageTimer =
              Timer(syncedMessageDuration, () => setState(() => showSyncedMessage = false));
        } else {
          if(mounted) {
            setState(() => showSyncedMessage = false);
          }
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
          bottom: 10, left: 18, right: 18, top: 10 + _additionalTopPadding(context)),
      child: Observer(
        builder: (_) => Row(
          spacing: 12,
          children: [
            (widget.dashboardViewModel.hasLightning)
                ? LightningSwitcher(
                    lightningMode: widget.lightningMode,
                    onLightningSwitchPress: widget.onLightningSwitchPress,
                  )
                : ChainIcon(
                    iconPath: widget.dashboardViewModel.wallet.currency.flatIconPath ?? "",
                    dashboardViewModel: widget.dashboardViewModel,
                    isSyncHeavy: widget.dashboardViewModel.isSyncHeavy,
                    showSyncedMessage: showSyncedMessage),
            SyncBar(
              dashboardViewModel: widget.dashboardViewModel,
              isSyncHeavy: widget.dashboardViewModel.isSyncHeavy,
              showSyncedMessage: showSyncedMessage,
            ),
            ModernButton.svg(
              iconColor: Theme.of(context).colorScheme.primary,
              size: 36,
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onSettingsButtonPress();
              },
              svgPath: "assets/new-ui/top-settings.svg",
              semanticLabel: S.of(context).settings_title,
            ),
          ],
        ),
      ),
    );

  //FIXME remove after this gets fixed flutter-side
  double _additionalTopPadding(BuildContext context) {
    if (Platform.isIOS && MediaQuery.of(context).viewPadding.top < 12) return 24;

    return 0;
  }
}
