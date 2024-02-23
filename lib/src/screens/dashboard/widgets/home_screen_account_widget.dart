import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

class HomeScreenAccountWidget extends StatelessWidget {
  HomeScreenAccountWidget({this.walletName, this.accountName});

  final String? walletName;
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async  {
        await showPopUp<void>(
    context: context,
    builder: (_) => getIt.get<MoneroAccountListPage>());
    },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(top: 25, bottom: 25, left: 25, right: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Text(
                    walletName ?? '',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                      color: Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Container(
                  child: Text(
                    accountName ?? '',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lato',
                      color: Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
