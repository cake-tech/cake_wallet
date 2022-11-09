import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/privacy_settings_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class AdvancedPrivacySettingsPage extends BasePage {
  AdvancedPrivacySettingsPage(this.privacySettingsViewModel, this.nodeViewModel);

  final PrivacySettingsViewModel privacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  String get title => S.current.privacy_settings;

  @override
  Widget body(BuildContext context) =>
      AdvancedPrivacySettingsBody(privacySettingsViewModel, nodeViewModel);
}

class AdvancedPrivacySettingsBody extends StatefulWidget {
  const AdvancedPrivacySettingsBody(this.privacySettingsViewModel, this.nodeViewModel, {Key? key})
      : super(key: key);

  final PrivacySettingsViewModel privacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  _AdvancedPrivacySettingsBodyState createState() =>
      _AdvancedPrivacySettingsBodyState(privacySettingsViewModel, nodeViewModel);
}

class _AdvancedPrivacySettingsBodyState
    extends State<AdvancedPrivacySettingsBody> {
  _AdvancedPrivacySettingsBodyState(this.privacySettingsViewModel, this.nodeViewModel);

  final PrivacySettingsViewModel privacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

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
                    padding: EdgeInsets.only(left: 24, right: 24, top: 24),
                    child: NodeForm(
                      formKey: _formKey,
                      nodeViewModel: nodeViewModel,
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
              onPressed: () {
                nodeViewModel.save();
              },
              text: S.of(context).continue_text,
              color: Theme.of(context).accentTextTheme.bodyText1!.color!,
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
