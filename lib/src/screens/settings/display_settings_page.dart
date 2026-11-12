import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_picker_sheet.dart';
import "package:cake_wallet/new-ui/widgets/pill_segmented_control.dart";
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_theme_choice.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/new-ui/widgets/modal_page_wrapper.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';

class DisplaySettingsPage extends StatelessWidget {
  DisplaySettingsPage(this._displaySettingsViewModel);

  final DisplaySettingsViewModel _displaySettingsViewModel;

  @override
  Widget build(BuildContext context) {
    final tabIconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.of(context).display,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        leadingSemanticLabel: S.of(context).seed_alert_back,
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      content: Observer(
        builder: (_) => Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsGroup(
              title: S.of(context).general,
              child: NewListSections(
                sections: {
                  "general": [
                    ListItemSelector(
                      keyValue: "display_settings_language",
                      label: S.of(context).language,
                      options: [LanguageService.list[_displaySettingsViewModel.languageCode] ?? ""],
                      optionImagePath: _flagPath(_displaySettingsViewModel.languageCode),
                      onTap: () => _showLanguagePicker(context),
                    ),
                    if (!_displaySettingsViewModel.disabledFiatApiMode)
                      ListItemSelector(
                        keyValue: "display_settings_fiat_currency",
                        label: S.of(context).settings_currency,
                        options: [_displaySettingsViewModel.fiatCurrencyLabel],
                        onTap: () => FiatCurrencyPickerSheet.show(
                          context: context,
                          selected: _displaySettingsViewModel.fiatCurrency,
                          onSelected: _displaySettingsViewModel.setFiatCurrency,
                        ),
                      ),
                  ],
                },
              ),
            ),
            if (responsiveLayoutUtil.shouldRenderMobileUI && DeviceInfo.instance.isMobile)
              _SettingsGroup(
                title: S.of(context).theme,
                child: Column(
                  spacing: 12,
                  children: [
                    PillSegmentedControl<ThemeMode>(
                      items: ThemeMode.values,
                      selectedItem: _displaySettingsViewModel.themeMode,
                      labelFor: (mode) => mode.name[0].toUpperCase() + mode.name.substring(1),
                      onSelected: _displaySettingsViewModel.setThemeMode,
                    ),
                    if (_displaySettingsViewModel.showThemePreview)
                      Container(
                        decoration: ShapeDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Semantics(
                          label: S.of(context).color_theme,
                          child: SettingsThemeChoicesCell(_displaySettingsViewModel),
                        ),
                      ),
                  ],
                ),
              ),
            _SettingsGroup(
              title: S.of(context).show_tabs,
              child: NewListSections(
                sections: {
                  "show_tabs": [
                    ListItemToggle(
                      keyValue: "apps",
                      label: S.of(context).apps,
                      iconPath: "assets/new-ui/navbar/apps.svg",
                      iconColor: tabIconColor,
                      value: _displaySettingsViewModel.shouldShowMarketPlaceInDashboard,
                      onChanged: _displaySettingsViewModel.setShouldShowMarketPlaceInDashbaord,
                    ),
                    ListItemToggle(
                      keyValue: "display_settings_charts",
                      label: S.of(context).charts,
                      iconPath: "assets/new-ui/navbar/charts.svg",
                      iconColor: tabIconColor,
                      value: _displaySettingsViewModel.shouldShowChartsInDashboard,
                      onChanged: _displaySettingsViewModel.setShouldShowChartsInDashboard,
                    ),
                  ],
                },
              ),
            ),
            _SettingsGroup(
              title: S.of(context).other_preferences,
              child: NewListSections(
                sections: {
                  "other_preferences": [
                    ListItemSelector(
                      keyValue: "display_settings_sync_status_display",
                      label: S.of(context).sync_status_display_mode,
                      options: [_displaySettingsViewModel.syncStatusDisplayMode.title],
                      onTap: () => _showSyncStatusDisplayPicker(context),
                    ),
                    ListItemToggle(
                      keyValue: "display_settings_show_buy_sell",
                      label: S.of(context).show_buy_sell_options,
                      value: !_displaySettingsViewModel.disableTradeOption,
                      onChanged: (show) => _displaySettingsViewModel.setDisableTradeOption(!show),
                    ),
                    ListItemToggle(
                      keyValue: "display_settings_show_nfts_tab",
                      label: S.of(context).show_nfts_tab,
                      subtitle: S.of(context).on_networks_that_support_them,
                      value: _displaySettingsViewModel.shouldShowNftsTab,
                      onChanged: _displaySettingsViewModel.setShouldShowNftsTab,
                    ),
                    ListItemToggle(
                      keyValue: "display_settings_show_address_book_popup",
                      label: S.of(context).show_address_book_popup,
                      subtitle: S.of(context).after_successful_transaction,
                      value: _displaySettingsViewModel.showAddressBookPopup,
                      onChanged: _displaySettingsViewModel.setShowAddressBookPopup,
                    ),
                  ],
                },
              ),
            ),
            if (FeatureFlag.customBackgroundEnabled)
              StandardListRow(
                title: "Custom background",
                isSelected: false,
                onTap: (_) => _pickImage(context),
              ),
          ],
        ),
      ),
    );
  }

  String _flagPath(String languageCode) =>
      "assets/images/flags/${LanguageService.localeCountryCode[languageCode]}.png";

  Future<void> _showLanguagePicker(BuildContext context) async {
    final items = LanguageService.list.keys.toList();
    final selectedAtIndex = items.indexOf(_displaySettingsViewModel.languageCode);

    await showPopUp<void>(
      context: context,
      builder: (_) => Picker(
        displayItem: (code) => LanguageService.list[code] ?? "",
        items: items,
        selectedAtIndex: selectedAtIndex,
        mainAxisAlignment: MainAxisAlignment.start,
        onItemSelected: _displaySettingsViewModel.onLanguageSelected,
        images: items.map((code) => Image.asset(_flagPath(code))).toList(),
        hintText: S.of(context).search_language,
        matchingCriteria: (code, searchText) =>
            LanguageService.list[code]?.toLowerCase().contains(searchText) ?? false,
        isSeparated: true,
      ),
    );
  }

  Future<void> _showSyncStatusDisplayPicker(BuildContext context) async {
    final items = SyncStatusDisplayMode.values.toList();
    final selectedAtIndex = items.indexOf(_displaySettingsViewModel.syncStatusDisplayMode);

    await showPopUp<void>(
      context: context,
      builder: (_) => Picker(
        items: items,
        selectedAtIndex: selectedAtIndex,
        mainAxisAlignment: MainAxisAlignment.start,
        onItemSelected: _displaySettingsViewModel.setSyncStatusDisplayMode,
        displayItem: (mode) => mode.title,
        isSeparated: false,
      ),
    );
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage(BuildContext context) async {
    if (_displaySettingsViewModel.backgroundImage.isNotEmpty) {
      final bool? shouldReplace = await showPopUp<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithTwoActions(
                alertTitle: S.of(context).replace,
                alertContent: S.of(context).customBackgroundDescription,
                rightButtonText: S.of(context).replace,
                leftButtonText: S.of(context).remove,
                actionRightButton: () => Navigator.of(context).pop(true),
                actionLeftButton: () => Navigator.of(context).pop(false));
          });

      if (shouldReplace == false) {
        // remove the current background by setting it as an empty string
        _displaySettingsViewModel.setBackgroundImage("");
        return;
      } else if (shouldReplace == null) {
        // user didn't choose anything, then just return
        return;
      }
    }

    final ImagePicker picker = ImagePicker();
    // Pick an image from the gallery
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _displaySettingsViewModel.setBackgroundImage(pickedFile.path);
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        child,
      ],
    );
  }
}
