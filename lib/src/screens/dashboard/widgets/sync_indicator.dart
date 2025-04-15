import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/core/sync_status_title.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator_icon.dart';

class SyncIndicator extends StatelessWidget {
  SyncIndicator({
    required this.dashboardViewModel,
    required this.onTap,
    super.key,
  });

  final DashboardViewModel dashboardViewModel;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final syncIndicatorWidth = 237.0;
      final status = dashboardViewModel.status;
      final statusText = syncStatusTitle(status);
      final progress = status.progress();
      final indicatorOffset = progress * syncIndicatorWidth;
      final indicatorWidth = progress < 1
          ? indicatorOffset > 0
              ? indicatorOffset
              : 0.0
          : syncIndicatorWidth;

      return ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 30,
            width: syncIndicatorWidth,
            color: Theme.of(context).extension<SyncIndicatorTheme>()!.notSyncedBackgroundColor,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                progress <= 1
                    ? Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: indicatorWidth,
                          height: 30,
                          color: Theme.of(context)
                              .extension<SyncIndicatorTheme>()!
                              .syncedBackgroundColor,
                        ))
                    : Offstage(),
                Padding(
                  padding: EdgeInsets.only(left: 24, right: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SyncIndicatorIcon(isSynced: status is SyncedSyncStatus),
                      Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: RollingText(statusText),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );
    });
  }
}

class RollingText extends StatelessWidget {
  const RollingText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final inAnimation = Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(animation);

        return ClipRect(
          child: SlideTransition(
            position: inAnimation,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).extension<SyncIndicatorTheme>()!.textColor,
        ),
      ),
    );
  }
}
