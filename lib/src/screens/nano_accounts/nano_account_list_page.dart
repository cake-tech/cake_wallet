import 'package:cake_wallet/src/widgets/picker_inner_wrapper_widget.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/view_model/nano_account_list/nano_account_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/monero_accounts/widgets/account_tile.dart';

class NanoAccountListPage extends StatelessWidget {
  NanoAccountListPage({required this.accountListViewModel});

  final NanoAccountListViewModel accountListViewModel;
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    double itemHeight = 80;
    double buttonHeight = 62;

    return Observer(builder: (_) {
      final accounts = accountListViewModel.accounts;
      return PickerInnerWrapperWidget(
        title: S.of(context).choose_account,
        itemsHeight: (itemHeight * accounts.length) + buttonHeight,
        children: [
          Expanded(
              child: Scrollbar(
            controller: controller,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              controller: controller,
              separatorBuilder: (context, index) => const VerticalSectionDivider(),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];

                return AccountTile(
                    isCurrent: account.isSelected,
                    accountName: account.label,
                    accountBalance: account.balance ?? '0.00',
                    currency: accountListViewModel.currency.toString(),
                    onTap: () {
                      if (account.isSelected) {
                        return;
                      }

                      accountListViewModel.select(account);
                      Navigator.of(context).pop();
                    },
                    onEdit: () async => await Navigator.of(context)
                        .pushNamed(Routes.nanoAccountCreation, arguments: account));
              },
            ),
          )),
          GestureDetector(
            onTap: () async => await Navigator.of(context).pushNamed(Routes.nanoAccountCreation),
            child: Container(
              height: buttonHeight,
              color: Theme.of(context).cardColor,
              padding: EdgeInsets.symmetric(horizontal: 24),
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
      );
    });
  }
}
