import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/account_list/account_list_store.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/palette.dart';

class AccountPage extends BasePage {
  String get title => 'Account';
  final Account account;

  AccountPage({this.account});

  @override
  Widget body(BuildContext context) => AccountForm(account);
}

class AccountForm extends StatefulWidget {
  final Account account;

  AccountForm(this.account);

  @override
  createState() => AccountFormState();
}

class AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void initState() {
    if (widget.account != null) _textController.text = widget.account.label;
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountListStore = Provider.of<AccountListStore>(context);

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Expanded(
                child: Center(
              child: TextFormField(
                decoration: InputDecoration(
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    hintText: S.of(context).account,
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Palette.cakeGreen, width: 2.0)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).focusColor, width: 1.0))),
                controller: _textController,
                validator: (value) {
                  accountListStore.validateAccountName(value);
                  return accountListStore.errorMessage;
                },
              ),
            )),
            Observer(
                builder: (_) => LoadingPrimaryButton(
                      onPressed: () async {
                        if (!_formKey.currentState.validate()) {
                          return;
                        }

                        if (widget.account != null) {
                          await accountListStore.renameAccount(
                              index: widget.account.id,
                              label: _textController.text);
                        } else {
                          await accountListStore.addAccount(
                              label: _textController.text);
                        }
                        Navigator.pop(context, _textController.text);
                      },
                      text:
                          widget.account != null ? 'Rename' : S.of(context).add,
                      color: Theme.of(context)
                          .primaryTextTheme
                          .button
                          .backgroundColor,
                      borderColor: Theme.of(context)
                          .primaryTextTheme
                          .button
                          .decorationColor,
                      isLoading: accountListStore.isAccountCreating,
                    ))
          ],
        ),
      ),
    );
  }
}
