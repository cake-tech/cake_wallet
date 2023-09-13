import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class NanoChangeRepPage extends BasePage {
  NanoChangeRepPage()
      : _formKey = GlobalKey<FormState>(),
        _addressController = TextEditingController() {
    dynamic wallet = getIt.get<AppStore>().wallet!;
    _addressController.text = wallet.representative as String;
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
                                          alertTitle: S.of(context).change_rep,
                                          alertContent: S.of(context).change_rep_message,
                                          rightButtonText: S.of(context).change,
                                          leftButtonText: S.of(context).cancel,
                                          actionRightButton: () => Navigator.pop(context, true),
                                          actionLeftButton: () => Navigator.pop(context, false));
                                    }) ??
                                false;

                            if (confirmed) {
                              try {
                                dynamic wallet = getIt.get<AppStore>().wallet!;
                                await wallet.changeRep(_addressController.text);
                                // TODO: show message saying success:

                                Navigator.of(context).pop();
                              } catch (e) {
                                throw e;
                              }
                            }
                          },
                          text: S.of(context).change,
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                        ),
                      )),
                    ],
                  )),
        ));
  }
}
