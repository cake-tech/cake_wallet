import 'package:cake_wallet/core/sync_status_title.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/svg.dart';

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
      padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 10.0),
      child: Observer(
        builder: (_) => Row(
          spacing: 12,
          children: [
            (dashboardViewModel.balanceViewModel.hasSecondAdditionalBalance ||
                    dashboardViewModel.balanceViewModel.hasSecondAvailableBalance)
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
              size: 44,
              onPressed: onSettingsButtonPress,
              svgPath: "assets/new-ui/top-settings.svg",
            ),
          ],
        ),
      ),
    );
  }
}

class LightningSwitcher extends StatelessWidget {
  const LightningSwitcher(
      {super.key, required this.lightningMode, required this.onLightningSwitchPress});

  final bool lightningMode;
  final VoidCallback onLightningSwitchPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InkWell(
        onTap: onLightningSwitchPress,
        child: Container(
          decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadiusGeometry.circular(900.0)),
              color: Theme.of(context).colorScheme.surfaceContainer),
          width: 84,
          height: 44,
          padding: EdgeInsets.all(4),
          child: Stack(
            children: [
              AnimatedContainer(
                alignment: Alignment.centerRight,
                margin: EdgeInsets.only(left: lightningMode ? 40 : 0),
                duration: Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 36,
                height: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(900.0)),
                    color: Theme.of(context).colorScheme.primary),
              ),
              Container(
                child: Row(
                  spacing: 4.0,
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: SvgPicture.asset(
                        key: ValueKey(lightningMode),
                        'assets/new-ui/switcher-bitcoin.svg',
                        width: 36,
                        height: 36,
                        colorFilter: ColorFilter.mode(
                          lightningMode
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: SvgPicture.asset(
                        key: ValueKey(lightningMode),
                        'assets/new-ui/switcher-lightning.svg',
                        width: 36,
                        height: 36,
                        colorFilter: ColorFilter.mode(
                          lightningMode
                              ? Theme.of(context).colorScheme.surfaceContainer
                              : Theme.of(context).colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChainIcon extends StatelessWidget {
  const ChainIcon(
      {super.key,
      required this.iconPath,
      required this.dashboardViewModel,
      required this.isSyncHeavy});

  final String iconPath;
  final bool isSyncHeavy;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final progress = dashboardViewModel.status.progress();
        final done = !isSyncHeavy || progress >= 1;

        return Stack(
          children: [
            AnimatedOpacity(
              duration: Duration(milliseconds: 100),
              opacity: done ? 0 : 1,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 100),
                child: CircularProgressIndicator(
                  key: ValueKey(progress),
                  value: progress,
                  color: Color(0xFFFFB84E),
                  strokeWidth: 2,
                ),
              ),
            ),
            AnimatedScale(
              duration: Duration(milliseconds: 150),
              scale: done ? 1 : 0.8,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 150),
                child: SvgPicture.asset(
                  key: ValueKey(progress >= 1),
                  iconPath,
                  width: 36,
                  height: 36,
                  colorFilter: ColorFilter.mode(
                      done
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withAlpha(128),
                      BlendMode.srcIn),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
        printV(status.runtimeType);
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


class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key,});


  final double size = 5;
  final Color color = const Color(0xFFFFC414);
  final Duration fadeOutDuration = const Duration(milliseconds: 900);
  final Duration restDuration = const Duration(milliseconds: 2000);
  final double restOpacity = 0.3;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.fadeOutDuration,
      reverseDuration: Duration.zero,
      value: 1.0,
    );
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await controller.animateTo(
        widget.restOpacity,
        curve: Curves.easeOutQuad,
        duration: widget.fadeOutDuration,
      );
      await Future.delayed(widget.restDuration);
      controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}