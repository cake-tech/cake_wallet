import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';

class NanoChangeRepPage extends BasePage {
  NanoChangeRepPage()
      : _formKey = GlobalKey<FormState>(),
        _addressController = TextEditingController() {
    // reaction((_) => nodeCreateOrEditViewModel.address, (String address) {
    //   if (address != _addressController.text) {
    //     _addressController.text = address;
    //   }
    // });

    // reaction((_) => nodeCreateOrEditViewModel.port, (String port) {
    //   if (port != _portController.text) {
    //     _portController.text = port;
    //   }
    // });

    // if (nodeCreateOrEditViewModel.hasAuthCredentials) {
    //   reaction((_) => nodeCreateOrEditViewModel.login, (String login) {
    //     if (login != _loginController.text) {
    //       _loginController.text = login;
    //     }
    //   });

    //   reaction((_) => nodeCreateOrEditViewModel.password, (String password) {
    //     if (password != _passwordController.text) {
    //       _passwordController.text = password;
    //     }
    //   });
    // }

    // _addressController.addListener(
    //     () => repViewModel.address = _addressController.text);
    // _portController.addListener(
    //     () => nodeCreateOrEditViewModel.port = _portController.text);
    // _loginController.addListener(
    //     () => nodeCreateOrEditViewModel.login = _loginController.text);
    // _passwordController.addListener(
    //     () => nodeCreateOrEditViewModel.password = _passwordController.text);
  }

  final GlobalKey<FormState> _formKey;
  final TextEditingController _addressController;

  // final CryptoCurrency type;

  @override
  String get title => S.current.change_rep;

  @override
  Widget body(BuildContext context) {
    return Container(
        padding: EdgeInsets.only(left: 24, right: 24),
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 24.0),
          content: Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: BaseTextFormField(
                        controller: _addressController,
                        hintText: S.of(context).node_address,
                        validator: AddressValidator(type: CryptoCurrency.nano),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          bottomSectionPadding: EdgeInsets.only(bottom: 24),
          bottomSection: Observer(
              builder: (_) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                          child: Container(
                        padding: EdgeInsets.only(right: 8.0),
                        child: LoadingPrimaryButton(
                          onPressed: () async {
                            final confirmed = await showPopUp<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertWithTwoActions(
                                          alertTitle: S.of(context).remove_node,
                                          alertContent: S.of(context).remove_node_message,
                                          rightButtonText: S.of(context).change,
                                          leftButtonText: S.of(context).cancel,
                                          actionRightButton: () => Navigator.pop(context, true),
                                          actionLeftButton: () => Navigator.pop(context, false));
                                    }) ??
                                false;

                            if (confirmed) {
                              // await editingNode!.delete();
                              Navigator.of(context).pop();
                            }
                          },
                          text: S.of(context).change,
                          color: Theme.of(context).accentTextTheme.bodyLarge!.color!,
                          textColor: Colors.white,
                        ),
                      )),
                    ],
                  )),
        ));
  }
}
