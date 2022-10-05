import 'package:cake_wallet/entities/generate_name.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/privacy_settings_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/wallet_name_validator.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class AdvancedPrivacySettingsPage extends BasePage {
  AdvancedPrivacySettingsPage(this.privacySettingsViewModel);

  final PrivacySettingsViewModel privacySettingsViewModel;

  @override
  String get title => S.current.privacy_settings;

  @override
  Widget body(BuildContext context) =>
      AdvancedPrivacySettingsBody(privacySettingsViewModel);
}

class AdvancedPrivacySettingsBody extends StatefulWidget {
  const AdvancedPrivacySettingsBody(this.privacySettingsViewModel, {Key key})
      : super(key: key);

  final PrivacySettingsViewModel privacySettingsViewModel;

  @override
  _AdvancedPrivacySettingsBodyState createState() =>
      _AdvancedPrivacySettingsBodyState(privacySettingsViewModel);
}

class _AdvancedPrivacySettingsBodyState
    extends State<AdvancedPrivacySettingsBody> {
  _AdvancedPrivacySettingsBodyState(this.privacySettingsViewModel);

  final PrivacySettingsViewModel privacySettingsViewModel;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 24),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...privacySettingsViewModel.settings.map(
              (item) => Observer(
                builder: (_) => SettingsSwitcherCell(
                  title: item.title,
                  value: item.value(),
                  onValueChange: item.onValueChange,
                ),
              ),
            ),
            Observer(
              builder: (_) {
                if (privacySettingsViewModel.addCustomNode) {
                  return Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        onChanged: (value) {},
                        controller: _controller,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).primaryTextTheme.title.color),
                        decoration: InputDecoration(
                          hintStyle: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .display3
                                  .color),
                          hintText: S.of(context).wallet_name,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display3
                                    .decorationColor,
                                width: 1.0),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display3
                                    .decorationColor,
                                width: 1.0),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () async {
                              final rName = await generateName();
                              FocusManager.instance.primaryFocus?.unfocus();

                              setState(() {
                                _controller.text = rName;
                                _controller.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: _controller.text.length),
                                );
                              });
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6.0),
                                color: Theme.of(context).hintColor,
                              ),
                              width: 34,
                              height: 34,
                              child: Image.asset(
                                'assets/images/refresh_icon.png',
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .display1
                                    .decorationColor,
                              ),
                            ),
                          ),
                        ),
                        validator: WalletNameValidator(),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
        bottomSectionPadding: EdgeInsets.all(24),
        bottomSection: Column(
          children: [
            LoadingPrimaryButton(
              onPressed: () {},
              text: S.of(context).continue_text,
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
            const SizedBox(height: 25),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.15),
              child: Text(
                S.of(context).settings_can_be_changed_later,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).accentTextTheme.display3.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
