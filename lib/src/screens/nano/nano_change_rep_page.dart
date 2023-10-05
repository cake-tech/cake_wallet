import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class NanoChangeRepPage extends BasePage {
  NanoChangeRepPage(WalletBase wallet)
      : _wallet = wallet,
        _addressController = TextEditingController() {
    _addressController.text = (wallet as NanoWallet).representative;
  }

  final TextEditingController _addressController;
  final WalletBase _wallet;

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
                                await nano!.changeRep(_wallet, _addressController.text);
                                Navigator.of(context).pop();
                              } catch (e) {
                                await showPopUp<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertWithOneAction(
                                          alertTitle: S.of(context).error,
                                          alertContent: e.toString(),
                                          buttonText: S.of(context).ok,
                                          buttonAction: () => Navigator.pop(context));
                                    });
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
