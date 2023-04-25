import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:mobx/mobx.dart';

class AdvancedPrivacySettingsPage extends BasePage {
  AdvancedPrivacySettingsPage(this.advancedPrivacySettingsViewModel, this.nodeViewModel)
      : _addressController = TextEditingController(),
        _portController = TextEditingController(),
        _loginController = TextEditingController(),
        _passwordController = TextEditingController() {
    reaction((_) => nodeViewModel.address, (String address) {
      if (address != _addressController.text) {
        _addressController.text = address;
      }
    });

    reaction((_) => nodeViewModel.port, (String port) {
      if (port != _portController.text) {
        _portController.text = port;
      }
    });

    if (nodeViewModel.hasAuthCredentials) {
      reaction((_) => nodeViewModel.login, (String login) {
        if (login != _loginController.text) {
          _loginController.text = login;
        }
      });

      reaction((_) => nodeViewModel.password, (String password) {
        if (password != _passwordController.text) {
          _passwordController.text = password;
        }
      });
    }

    _addressController.addListener(() => nodeViewModel.address = _addressController.text);
    _portController.addListener(() => nodeViewModel.port = _portController.text);
    _loginController.addListener(() => nodeViewModel.login = _loginController.text);
    _passwordController.addListener(() => nodeViewModel.password = _passwordController.text);
  }

  final TextEditingController _addressController;
  final TextEditingController _portController;
  final TextEditingController _loginController;
  final TextEditingController _passwordController;

  final AdvancedPrivacySettingsViewModel advancedPrivacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  String get title => S.current.privacy_settings;

  @override
  Widget body(BuildContext context) => AdvancedPrivacySettingsBody(
        privacySettingsViewModel: advancedPrivacySettingsViewModel,
        nodeViewModel: nodeViewModel,
        addressController: _addressController,
        portController: _portController,
        loginController: _loginController,
        passwordController: _passwordController,
      );
}

class AdvancedPrivacySettingsBody extends StatefulWidget {
  AdvancedPrivacySettingsBody({
    required this.privacySettingsViewModel,
    required this.nodeViewModel,
    required this.addressController,
    required this.portController,
    required this.loginController,
    required this.passwordController,
  });

  final TextEditingController addressController;
  final TextEditingController portController;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final AdvancedPrivacySettingsViewModel privacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  _AdvancedPrivacySettingsBodyState createState() => _AdvancedPrivacySettingsBodyState();
}

class _AdvancedPrivacySettingsBodyState extends State<AdvancedPrivacySettingsBody> {
  _AdvancedPrivacySettingsBodyState();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(bottom: 24),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Observer(builder: (_) {
              return SettingsChoicesCell(
                ChoicesListItem<FiatApiMode>(
                  title: S.current.disable_fiat,
                  items: FiatApiMode.all,
                  selectedItem: widget.privacySettingsViewModel.fiatApiMode,
                  onItemSelected: (FiatApiMode mode) =>
                      widget.privacySettingsViewModel.setFiatApiMode(mode),
                ),
              );
            }),
            Observer(builder: (_) {
              return SettingsChoicesCell(
                ChoicesListItem<ExchangeApiMode>(
                  title: S.current.exchange,
                  items: ExchangeApiMode.all,
                  selectedItem: widget.privacySettingsViewModel.exchangeStatus,
                  onItemSelected: (ExchangeApiMode mode) =>
                      widget.privacySettingsViewModel.setExchangeApiMode(mode),
                ),
              );
            }),
            Observer(builder: (_) {
              return Column(
                children: [
                  SettingsSwitcherCell(
                    title: S.current.add_custom_node,
                    value: widget.privacySettingsViewModel.addCustomNode,
                    onValueChange: (_, __) => widget.privacySettingsViewModel.toggleAddCustomNode(),
                  ),
                  if (widget.privacySettingsViewModel.addCustomNode)
                    Padding(
                      padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                      child: NodeForm(
                        formKey: _formKey,
                        nodeViewModel: widget.nodeViewModel,
                        addressController: widget.addressController,
                        portController: widget.portController,
                        loginController: widget.loginController,
                        passwordController: widget.passwordController,
                      ),
                    )
                ],
              );
            }),
          ],
        ),
        bottomSectionPadding: EdgeInsets.all(24),
        bottomSection: Column(
          children: [
            LoadingPrimaryButton(
              onPressed: () {
                if (widget.privacySettingsViewModel.addCustomNode) {
                  if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
                    return;
                  }

                  widget.nodeViewModel.save();
                }

                Navigator.pop(context);
              },
              text: S.of(context).continue_text,
              color: Theme.of(context).accentTextTheme.bodyText1!.color!,
              textColor: Colors.white,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
              child: Text(
                S.of(context).settings_can_be_changed_later,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).accentTextTheme.headline2?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
