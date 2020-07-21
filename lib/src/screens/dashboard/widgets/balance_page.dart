import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard_view_model.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator.dart';

class BalancePage extends StatelessWidget {
  BalancePage({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;
  final triangleImage = Image.asset('assets/images/triangle.png');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: 24
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            child: SyncIndicator(dashboardViewModel: dashboardViewModel)
          ),
          Container(
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Observer(
                  builder: (_) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          dashboardViewModel.wallet.currency.toString(),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: PaletteDark.cyanBlue,
                            height: 1
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: triangleImage,
                        )
                      ],
                    );
                  }
                ),
                Observer(
                  builder: (_) {
                    return Text(
                      dashboardViewModel.balance.totalBalance,
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1
                      ),
                    );
                  }
                ),
                Observer(
                  builder: (_) {
                    return Text(
                      '\$ 0.00',
                      style: TextStyle(
                        fontSize: 18,
                        color: PaletteDark.cyanBlue,
                        height: 1
                      ),
                    );
                  }
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

