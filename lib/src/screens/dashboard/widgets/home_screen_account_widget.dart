import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

class HomeScreenAccountWidget extends StatelessWidget {
  HomeScreenAccountWidget({this.walletName, this.accountName});

  final String? walletName;
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showPopUp<void>(context: context, builder: (_) => getIt.get<MoneroAccountListPage>());
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(25.0),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Row(
                  children: [
                    Padding(padding: EdgeInsets.only(left: 20)),
                    Container(
                      child: Text(
                        accountName ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    Container(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
