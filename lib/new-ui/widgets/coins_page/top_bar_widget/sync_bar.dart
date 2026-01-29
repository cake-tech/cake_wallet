import 'package:cake_wallet/core/sync_status_title.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/top_bar_widget/pulsing_dot.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SyncBar extends StatelessWidget {
  SyncBar({super.key, required this.dashboardViewModel, required this.isSyncHeavy});

  final DashboardViewModel dashboardViewModel;
  final bool isSyncHeavy;

  static const failStatuses = [
    FailedSyncStatus,
    LostConnectionSyncStatus,
    TimedOutSyncStatus,
    UnsupportedSyncStatus,
  ];

  static const progressStatuses = [
    SyncingSyncStatus,
    NotConnectedSyncStatus,
    SyncronizingSyncStatus,
    AttemptingSyncStatus,
    StartingScanSyncStatus,
    AttemptingScanSyncStatus,
    SyncedTipSyncStatus,
    ProcessingSyncStatus,
    ConnectingSyncStatus,
    ConnectedSyncStatus,
  ];

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final status = dashboardViewModel.status;
        final Widget? icon = _getIcon(context, status.runtimeType);

        return Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (_showDot())
                PulsingDot(),
              if (_showFullBar())
                GestureDetector(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pushNamed(Routes.connectionSync);
                  },
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 100),
                    child: Container(
                      key: ValueKey(status.runtimeType),
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        border: _getBorder(context, status.runtimeType),
                        color: _getBackgroundColor(context, status.runtimeType),
                      ),
                      child: Row(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (icon != null) icon,
                          if (dashboardViewModel.silentPaymentsScanningActive &&
                              progressStatuses.contains(status.runtimeType)) ...[
                            Text(
                              "${(status.progress() * 100).toInt()}%",
                              style: TextStyle(fontSize: 12, color: Color(0xFFEFBA5E)),
                            ),
                            Text(
                              "·",
                              style: TextStyle(fontSize: 12),
                            )
                          ],
                          Text(
                            syncStatusTitle(
                                status, dashboardViewModel.settingsStore.syncStatusDisplayMode),
                            style: _getTextStyle(context, status.runtimeType),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color? _getBackgroundColor(BuildContext context, Type status) {
    if (failStatuses.contains(status)) {
      return Theme.of(context).colorScheme.errorContainer.withAlpha(64);
    }

    return null;
  }

  Border? _getBorder(BuildContext context, Type status) {
    if (progressStatuses.contains(status)) {
      return Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh, width: 1);
    }

    return null;
  }

  TextStyle? _getTextStyle(BuildContext context, Type status) {
    if (failStatuses.contains(status)) {
      return TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.error);
    } else {
      return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurfaceVariant);
    }
  }

  Widget? _getIcon(BuildContext context, Type status) {
    if (status == LostConnectionSyncStatus || status == FailedSyncStatus) {
      return SvgPicture.asset(
        "assets/new-ui/offline.svg",
        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.error, BlendMode.srcIn),
      );
    }

    if (failStatuses.contains(status)) {
      return SvgPicture.asset(
        "assets/new-ui/warning.svg",
        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.error, BlendMode.srcIn),
      );
    }

    final List<Widget> children = [];

    if (dashboardViewModel.isTorEnabled) {
      children.add(SvgPicture.asset("assets/new-ui/tor_sync.svg",
          colorFilter: ColorFilter.mode(Color(0xFF8A38F5), BlendMode.srcIn)));
    }
    if (dashboardViewModel.hasMweb) {
      children.add(SvgPicture.asset(
        "assets/new-ui/mweb_sync.svg",
        colorFilter:
        ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
      ));
    }
    if (dashboardViewModel.hasSilentPayments) {
      children.add(SvgPicture.asset(
        "assets/new-ui/silent_sync.svg",
        colorFilter: ColorFilter.mode(Color(0xFFEFBA5E), BlendMode.srcIn),
      ));
    }

    return Row(
      spacing: 8,
      children: children,
    );
  }

  bool _showFullBar() {
    if (dashboardViewModel.status.runtimeType == SyncedSyncStatus) return false;
    return isSyncHeavy || failStatuses.contains(dashboardViewModel.status.runtimeType);
  }

  bool _showDot() {
    return !isSyncHeavy && progressStatuses.contains(dashboardViewModel.status.runtimeType);
  }
}