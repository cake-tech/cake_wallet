import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BalancePage extends StatelessWidget {
  BalancePage({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Container(
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Observer(
                  builder: (_) {
                    return Text(
                      dashboardViewModel.wallet.currency.toString(),
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: PaletteDark.cyanBlue,
                          height: 1
                      ),
                    );
                  }
              ),
              Observer(
                  builder: (_) {
                    return Text(
                      dashboardViewModel.balanceViewModel.cryptoBalance,
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
                      dashboardViewModel.balanceViewModel.fiatBalance,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: PaletteDark.cyanBlue,
                          height: 1
                      ),
                    );
                  }
              ),
            ],
          ),
        ),
      ),
    );
  }
}

