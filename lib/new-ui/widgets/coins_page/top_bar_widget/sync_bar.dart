import 'package:cake_wallet/core/sync_status_title.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/settings/manage_nodes_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import "package:cake_wallet/themes/core/theme_extension.dart";
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/sync_status.dart';
import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SyncBar extends StatelessWidget {
  const SyncBar({
    required this.dashboardViewModel,
    required this.isSyncHeavy,
    required this.showSyncedMessage,
    super.key,
  });

  final DashboardViewModel dashboardViewModel;
  final bool isSyncHeavy;
  final bool showSyncedMessage;

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

  static const syncedColor = Color(0xFF12A439);

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) {
          final status = dashboardViewModel.status;
          if (!_showFullBar) {
            return _buildCompactBar(context);
          }

          final Widget? icon = _getIcon(context, status.runtimeType);
          final statusTitle = _statusTitle(context, status);
          final silentPaymentsProgress = _silentPaymentsProgress(status);
          final barHeight = silentPaymentsProgress == null ? 36.0 : 40.0;

          // A single node: the localized status text (plus any active
          // Tor/MWEB/Silent Payments badge) is the label, and the hint says
          // where tapping leads. Everything inside is redundant with it.
          return Semantics(
            button: true,
            label: _statusSemanticsLabel(context, status, statusTitle),
            value: silentPaymentsProgress,
            hint: S.of(context).manage_nodes,
            onTap: () => _openNodeManagement(context),
            child: ExcludeSemantics(
              child: GestureDetector(
                onTap: () => _openNodeManagement(context),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: OverflowBox(
                    key: ValueKey(status.runtimeType),
                    alignment: Alignment.center,
                    minHeight: barHeight,
                    maxHeight: barHeight,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        border: _getBorder(context, status.runtimeType),
                        color: _getBackgroundColor(context, status.runtimeType),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        spacing: 8,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (icon != null) icon,
                          if (silentPaymentsProgress != null) ...[
                            Text(
                              silentPaymentsProgress,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.customColors.warningOutlineColor,
                              ),
                            ),
                            Text(
                              "·",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          Flexible(
                            child: Text(
                              statusTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _getTextStyle(context, status.runtimeType),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  void _openNodeManagement(BuildContext context) {
    CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withAlpha(85),
      builder: (context) => FractionallySizedBox(
        child: Material(
          child: getIt.get<ManageNodesPage>(param1: false),
        ),
      ),
    );
  }

  /// Compact mode shows sync state with a pulsing dot (and a Tor glyph) only, so
  /// the whole row needs a text equivalent.
  Widget _buildCompactBar(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 6,
      children: [
        if (dashboardViewModel.isTorEnabled)
          const CakeImageWidget(
            imageUrl: "assets/new-ui/tor.svg",
            width: 20,
            height: 20,
          ),
        if (_showDot()) const CupertinoActivityIndicator(radius: 8),
        if (_showLightSyncCheck()) const Icon(Icons.check, color: syncedColor, size: 18),
      ],
    );

    final label = _joinLabels([
      if (dashboardViewModel.isTorEnabled) S.of(context).tor_connection,
      if (_showDot()) S.of(context).synchronizing,
      if (_showLightSyncCheck()) S.of(context).sync_synced,
    ]);

    if (label.isEmpty) {
      return row;
    }

    return Semantics(label: label, child: ExcludeSemantics(child: row));
  }

  bool get _isShowingSyncedMessage =>
      showSyncedMessage && dashboardViewModel.status.runtimeType == SyncedSyncStatus;

  String _statusTitle(BuildContext context, SyncStatus status) {
    final title = syncStatusTitle(status, dashboardViewModel.settingsStore.syncStatusDisplayMode);

    return title.isNotEmpty ? title : S.of(context).synchronizing;
  }

  String _statusSemanticsLabel(BuildContext context, SyncStatus status, String statusTitle) {
    final isFailure = failStatuses.contains(status.runtimeType);

    return _joinLabels([
      statusTitle,
      if (!isFailure && dashboardViewModel.isTorEnabled) S.of(context).tor_connection,
      if (!isFailure && dashboardViewModel.hasMweb) S.of(context).litecoin_mweb,
      if (!isFailure && dashboardViewModel.hasSilentPayments) S.of(context).silent_payments,
    ]);
  }

  String _joinLabels(List<String> parts) => parts.where((part) => part.isNotEmpty).join(", ");

  String? _silentPaymentsProgress(SyncStatus status) {
    if (!dashboardViewModel.hasSilentPayments ||
        !dashboardViewModel.silentPaymentsScanningActive ||
        status is! SyncingSyncStatus) {
      return null;
    }

    return "${(status.progress() * 100).toInt()}%";
  }

  Color? _getBackgroundColor(BuildContext context, Type status) {
    if (failStatuses.contains(status)) {
      return Theme.of(context).colorScheme.errorContainer.withAlpha(64);
    }

    return null;
  }

  Border? _getBorder(BuildContext context, Type status) {
    if (progressStatuses.contains(status) || _isShowingSyncedMessage) {
      return Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh, width: 1);
    }

    return null;
  }

  TextStyle? _getTextStyle(BuildContext context, Type status) {
    final Color color;
    if (failStatuses.contains(status)) {
      color = Theme.of(context).colorScheme.error;
    } else if (status == SyncedSyncStatus) {
      color = syncedColor;
    } else {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: color);
  }

  Widget? _getIcon(BuildContext context, Type status) {
    if (status == SyncedSyncStatus) {
      return const Icon(Icons.check, color: syncedColor, size: 12);
    }

    if (status == LostConnectionSyncStatus) {
      return CakeImageWidget(
        imageUrl: "assets/new-ui/offline.svg",
        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.error, BlendMode.srcIn),
      );
    }

    if (failStatuses.contains(status)) {
      return CakeImageWidget(
        imageUrl: "assets/new-ui/warning.svg",
        colorFilter: ColorFilter.mode(Theme.of(context).colorScheme.error, BlendMode.srcIn),
      );
    }

    final List<Widget> children = [];

    if (dashboardViewModel.isTorEnabled) {
      children.add(
        const CakeImageWidget(
          imageUrl: "assets/new-ui/tor_sync.svg",
          colorFilter: ColorFilter.mode(Color(0xFF8A38F5), BlendMode.srcIn),
        ),
      );
    }
    if (dashboardViewModel.hasMweb) {
      children.add(
        CakeImageWidget(
          imageUrl: "assets/new-ui/mweb_sync.svg",
          colorFilter:
              ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
        ),
      );
    }
    if (dashboardViewModel.hasSilentPayments) {
      children.add(
        CakeImageWidget(
          imageUrl: "assets/new-ui/silent_sync.svg",
          width: 16,
          height: 16,
          colorFilter: ColorFilter.mode(context.customColors.warningOutlineColor, BlendMode.srcIn),
        ),
      );
    }

    if (children.isEmpty) {
      return null;
    }

    return Row(
      spacing: 8,
      children: children,
    );
  }

  bool get replacesWalletName => replacesWalletNameForStatus(
        dashboardViewModel.status.runtimeType,
        isSyncHeavy: isSyncHeavy,
        showSyncedMessage: _isShowingSyncedMessage,
      );

  static bool replacesWalletNameForStatus(
    Type status, {
    required bool isSyncHeavy,
    required bool showSyncedMessage,
  }) {
    if (status == SyncedSyncStatus) {
      return showSyncedMessage;
    }

    return isSyncHeavy || progressStatuses.contains(status) || failStatuses.contains(status);
  }

  bool get hasCompactContent =>
      dashboardViewModel.isTorEnabled || _showDot() || _showLightSyncCheck();

  bool get _showFullBar {
    if (dashboardViewModel.status.runtimeType == SyncedSyncStatus) {
      return isSyncHeavy && _isShowingSyncedMessage;
    }

    return isSyncHeavy || failStatuses.contains(dashboardViewModel.status.runtimeType);
  }

  bool _showDot() =>
      !isSyncHeavy && progressStatuses.contains(dashboardViewModel.status.runtimeType);

  bool _showLightSyncCheck() => !isSyncHeavy && _isShowingSyncedMessage;
}
