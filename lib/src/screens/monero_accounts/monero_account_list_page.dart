import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cake_wallet/src/screens/monero_accounts/widgets/account_tile.dart';

class MoneroAccountListPage extends StatefulWidget {
  MoneroAccountListPage({@required this.accountListViewModel});

  final MoneroAccountListViewModel accountListViewModel;

  @override
  MoneroAccountListPageForm createState() =>
      MoneroAccountListPageForm(accountListViewModel);
}

class MoneroAccountListPageForm extends State<MoneroAccountListPage> {
  MoneroAccountListPageForm(this.accountListViewModel);

  final MoneroAccountListViewModel accountListViewModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(
                color: PaletteDark.darkNightBlue.withOpacity(0.75)),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(left: 24, right: 24),
                    child: Text(
                      S.of(context).choose_account,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                    child: GestureDetector(
                      onTap: () => null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        child: Container(
                          height: 296,
                          color: Theme.of(context)
                              .accentTextTheme
                              .title
                              .backgroundColor,
                          child: Column(
                            children: <Widget>[
                              Expanded(child: Observer(builder: (_) {
                                final accounts =
                                    widget.accountListViewModel.accounts;

                                return ListView.separated(
                                  separatorBuilder: (context, index) => Divider(
                                      color: Theme.of(context).dividerColor,
                                      height: 1),
                                  itemCount: accounts.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final account = accounts[index];

                                    return AccountTile(
                                        isCurrent: account.isSelected,
                                        accountName: account.label,
                                        onTap: () {
                                          if (account.isSelected) {
                                            return;
                                          }

                                          widget.accountListViewModel
                                              .select(account);
                                          Navigator.of(context).pop();
                                        });
                                  },
                                );
                              })),
                              GestureDetector(
                                onTap: () async => await Navigator.of(context)
                                    .pushNamed(Routes.accountCreation),
                                child: Container(
                                  height: 62,
                                  color: Colors.white,
                                  padding: EdgeInsets.only(left: 24, right: 24),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.add,
                                          color: PaletteDark.darkNightBlue,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(left: 5),
                                          child: Text(
                                            S.of(context).create_new_account,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: PaletteDark.darkNightBlue,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
