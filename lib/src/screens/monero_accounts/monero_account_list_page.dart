import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/monero_account_list/monero_account_list_view_model.dart';
import 'package:cake_wallet/src/screens/monero_accounts/widgets/account_tile.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/src/widgets/alert_close_button.dart';

class MoneroAccountListPage extends StatelessWidget {
  MoneroAccountListPage({required this.accountListViewModel})
    : backgroundHeight = 194,
      thumbHeight = 72,
      isAlwaysShowScrollThumb = false,
      controller = ScrollController() {
    controller.addListener(() {
      final scrollOffsetFromTop = controller.hasClients
          ? (controller.offset / controller.position.maxScrollExtent * (backgroundHeight - thumbHeight))
          : 0.0;
      accountListViewModel.setScrollOffsetFromTop(scrollOffsetFromTop);
    });
  }

  final MoneroAccountListViewModel accountListViewModel;

  ScrollController controller;
  double backgroundHeight;
  double thumbHeight;
  bool isAlwaysShowScrollThumb;

  @override
  Widget build(BuildContext context) {
    return AlertBackground(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Column(
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
                            fontFamily: 'Lato',
                            decoration: TextDecoration.none,
                            color: Colors.white
                        ),
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
                            color: Theme.of(context).textTheme!.displayLarge!.decorationColor!,
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                    child: Observer(
                                        builder: (_) {
                                          final accounts = accountListViewModel.accounts;
                                          isAlwaysShowScrollThumb = accounts == null
                                              ? false
                                              : accounts.length > 3;

                                          return Stack(
                                            alignment: Alignment.center,
                                            children: <Widget>[
                                              ListView.separated(
                                                padding: EdgeInsets.zero,
                                                controller: controller,
                                                separatorBuilder: (context, index) =>
                                                const SectionDivider(),
                                                itemCount: accounts.length ?? 0,
                                                itemBuilder: (context, index) {
                                                  final account = accounts[index];

                                            return AccountTile(
                                                isCurrent: account.isSelected,
                                                accountName: account.label,
                                                accountBalance: account.balance ?? '0.00',
                                                currency: accountListViewModel
                                                    .currency.toString(),
                                                onTap: () {
                                                  if (account.isSelected) {
                                                    return;
                                                  }

                                                        accountListViewModel
                                                            .select(account);
                                                        Navigator.of(context).pop();
                                                      },
                                                      onEdit: () async =>
                                                      await Navigator.of(context)
                                                          .pushNamed(
                                                          Routes.accountCreation,
                                                          arguments: account));
                                                },
                                              ),
                                              isAlwaysShowScrollThumb
                                                  ? CakeScrollbar(
                                                  backgroundHeight: backgroundHeight,
                                                  thumbHeight: thumbHeight,
                                                  fromTop: accountListViewModel
                                                      .scrollOffsetFromTop
                                              )
                                                  : Offstage(),
                                            ],
                                          );
                                        }
                                    )
                                ),
                                GestureDetector(
                                  onTap: () async => await Navigator.of(context)
                                      .pushNamed(Routes.accountCreation),
                                  child: Container(
                                    height: 62,
                                    color: Theme.of(context).cardColor,
                                    padding: EdgeInsets.only(left: 24, right: 24),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.only(left: 5),
                                            child: Text(
                                              S.of(context).create_new_account,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Lato',
                                                color: Colors.white,
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
                SizedBox(height: ResponsiveLayoutUtil.kPopupSpaceHeight),
                AlertCloseButton()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
