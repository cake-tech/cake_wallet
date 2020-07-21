import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard_view_model.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';

class SyncIndicator extends StatelessWidget {
  SyncIndicator({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final syncIndicatorWidth = 250.0;
        final status = dashboardViewModel.status;
        final statusText = status.title();
        final progress = status.progress();
        final indicatorOffset = progress * syncIndicatorWidth;
        final indicatorWidth =
        progress <= 1 ? syncIndicatorWidth - indicatorOffset : 0.0;
        final indicatorColor = status is SyncedSyncStatus
                               ? PaletteDark.brightGreen
                               : PaletteDark.orangeYellow;

        return ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          child: Container(
            height: 30,
            width: syncIndicatorWidth,
            color: PaletteDark.lightNightBlue,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                progress <= 1
                ? Positioned(
                    left: indicatorOffset,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: indicatorWidth,
                      height: 30,
                      color: PaletteDark.oceanBlue,
                    )
                )
                : Offstage(),
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        height: 4,
                        width: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: indicatorColor
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: PaletteDark.wildBlue
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }
}