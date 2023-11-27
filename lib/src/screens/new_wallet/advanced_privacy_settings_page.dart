import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/seed_phrase_length.dart';
import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_form.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/themes/extensions/new_wallet_theme.dart';
import 'package:cake_wallet/view_model/node_list/node_create_or_edit_view_model.dart';
import 'package:cake_wallet/view_model/advanced_privacy_settings_view_model.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class AdvancedPrivacySettingsPage extends BasePage {
  AdvancedPrivacySettingsPage(this.advancedPrivacySettingsViewModel, this.nodeViewModel);

  final AdvancedPrivacySettingsViewModel advancedPrivacySettingsViewModel;
  final NodeCreateOrEditViewModel nodeViewModel;

  @override
  String get title => S.current.privacy_settings;

  @override
  Widget body(BuildContext context) =>
      AdvancedPrivacySettingsBody(advancedPrivacySettingsViewModel, nodeViewModel);
}

class AdvancedPrivacySettingsBody extends StatefulWidget {
  const AdvancedPrivacySettingsBody(this.privacySettingsViewModel, this.nodeViewModel, {Key? key})
      : super(key: key);

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
                      ),
                    )
                ],
              );
            }),
            if (widget.privacySettingsViewModel.hasSeedPhraseLengthOption)
              Observer(builder: (_) {
                return SettingsPickerCell<SeedPhraseLength>(
                  title: S.current.seed_phrase_length,
                  items: SeedPhraseLength.values,
                  selectedItem: widget.privacySettingsViewModel.seedPhraseLength,
                  onItemSelected: (SeedPhraseLength length) {
                    widget.privacySettingsViewModel.setSeedPhraseLength(length);
                  },
                );
              }),
            if (widget.privacySettingsViewModel.hasSeedTypeOption)
              Observer(builder: (_) {
                return SettingsChoicesCell(
                  ChoicesListItem<SeedType>(
                    title: S.current.seedtype,
                    items: SeedType.all,
                    selectedItem: widget.privacySettingsViewModel.seedType,
                    onItemSelected: widget.privacySettingsViewModel.setSeedType,
                  ),
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
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
            ),
            const SizedBox(height: 25),
            LayoutBuilder(
              builder: (_, constraints) => SizedBox(
                width: constraints.maxWidth * 0.8,
                child: Text(
                  S.of(context).settings_can_be_changed_later,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).extension<NewWalletTheme>()!.hintTextColor,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
