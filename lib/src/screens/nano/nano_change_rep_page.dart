import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class NanoChangeRepPage extends BasePage {
  NanoChangeRepPage({required SettingsStore settingsStore, required WalletBase wallet})
      : _wallet = wallet,
        _settingsStore = settingsStore,
        _addressController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    _addressController.text = nano!.getRepresentative(wallet);
  }

  final TextEditingController _addressController;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;

  final GlobalKey<FormState> _formKey;

  @override
  String get title => S.current.change_rep;

  @override
  Widget body(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.only(left: 24, right: 24),
        child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.only(bottom: 24.0),
          content: Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AddressTextField(
                        controller: _addressController,
                        onURIScanned: (uri) {
                          final paymentRequest = PaymentRequest.fromUri(uri);
                          _addressController.text = paymentRequest.address;
                        },
                        options: [
                          AddressTextFieldOption.paste,
                          AddressTextFieldOption.qrCode,
                        ],
                        buttonColor: Theme.of(context).extension<AddressTheme>()!.actionButtonColor,
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
                            if (_formKey.currentState != null &&
                                !_formKey.currentState!.validate()) {
                              return;
                            }

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
                                _settingsStore.defaultNanoRep = _addressController.text;

                                await nano!.changeRep(_wallet, _addressController.text);

                                await showPopUp<void>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertWithOneAction(
                                          alertTitle: S.of(context).successful,
                                          alertContent: S.of(context).change_rep_successful,
                                          buttonText: S.of(context).ok,
                                          buttonAction: () => Navigator.pop(context));
                                    });
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
        ),
      ),
    );
  }
}
