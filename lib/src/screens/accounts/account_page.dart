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
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';

class AccountPage extends BasePage {
  AccountPage({this.account});

  final Account account;

  @override
  String get title => S.current.account;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => AccountForm(account);
}

class AccountForm extends StatefulWidget {
  AccountForm(this.account);

  final Account account;

  @override
  AccountFormState createState() => AccountFormState();
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

    _textController.addListener(() {
      if (_textController.text.isNotEmpty) {
        accountListStore.setDisabledStatus(false);
      } else {
        accountListStore.setDisabledStatus(true);
      }
    });

    return Form(
      key: _formKey,
      child: Container(
        color: PaletteDark.historyPanel,
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: <Widget>[
            Expanded(
                child: Center(
                  child: BaseTextFormField(
                    controller: _textController,
                    hintText: S.of(context).account,
                    validator: (value) {
                      accountListStore.validateAccountName(value);
                      return accountListStore.errorMessage;
                    },
                  )
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
                        Navigator.of(context).pop(_textController.text);
                      },
                      text:
                          widget.account != null ? S.of(context).rename : S.of(context).add,
                      color: Colors.green,
                      textColor: Colors.white,
                      isLoading: accountListStore.isAccountCreating,
                      isDisabled: accountListStore.isDisabledStatus,
                    ))
          ],
        ),
      ),
    );
  }
}
