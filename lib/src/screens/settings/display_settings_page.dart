import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_theme_choice.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';

class DisplaySettingsPage extends BasePage {
  DisplaySettingsPage(this._displaySettingsViewModel);

  @override
  String get title => S.current.display_settings;

  final DisplaySettingsViewModel _displaySettingsViewModel;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Observer(builder: (_) {
        return Container(
          padding: EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSwitcherCell(
                title: S.of(context).apps,
                value: _displaySettingsViewModel.shouldShowMarketPlaceInDashboard,
                onValueChange: (_, bool value) {
                  _displaySettingsViewModel.setShouldShowMarketPlaceInDashbaord(value);
                },
              ),
              SettingsSwitcherCell(
                title: S.of(context).show_address_book_popup,
                value: _displaySettingsViewModel.showAddressBookPopup,
                onValueChange: (_, bool value) {
                  _displaySettingsViewModel.setShowAddressBookPopup(value);
                },
              ),
              SettingsPickerCell<SyncStatusDisplayMode>(
                title: S.current.sync_status_display_mode,
                items: SyncStatusDisplayMode.values.toList(),
                selectedItem: _displaySettingsViewModel.syncStatusDisplayMode,
                onItemSelected: (SyncStatusDisplayMode mode) =>
                    _displaySettingsViewModel.setSyncStatusDisplayMode(mode),
                displayItem: (SyncStatusDisplayMode mode) => mode.title,
                isGridView: false,
              ),
              if (_displaySettingsViewModel.showDisplayAmountsInSatoshiSetting)
                SettingsPickerCell<BitcoinAmountDisplayMode>(
                  title: "Bitcoin Amount Display", // ToDo (Konsti) localize
                  items: BitcoinAmountDisplayMode.all,
                  selectedItem: _displaySettingsViewModel.displayAmountsInSatoshi,
                  onItemSelected: _displaySettingsViewModel.setDisplayAmountsInSatoshi,
                  displayItem: (mode) => mode.title,
                  isGridView: false,
                ),
              //if (!isHaven) it does not work correctly
              if (!_displaySettingsViewModel.disabledFiatApiMode)
                SettingsPickerCell<FiatCurrency>(
                  title: S.of(context).settings_currency,
                  searchHintText: S.of(context).search_currency,
                  items: FiatCurrency.all,
                  selectedItem: _displaySettingsViewModel.fiatCurrency,
                  onItemSelected: (FiatCurrency currency) =>
                      _displaySettingsViewModel.setFiatCurrency(currency),
                  images: FiatCurrency.all
                      .map((e) => Image.asset("assets/images/flags/${e.countryCode}.png"))
                      .toList(),
                  isGridView: true,
                  matchingCriteria: (FiatCurrency currency, String searchText) {
                    return currency.title.toLowerCase().contains(searchText) ||
                        currency.fullName.toLowerCase().contains(searchText);
                  },
                ),
              SettingsPickerCell<String>(
                title: S.of(context).settings_change_language,
                searchHintText: S.of(context).search_language,
                items: LanguageService.list.keys.toList(),
                displayItem: (dynamic code) {
                  return LanguageService.list[code] ?? '';
                },
                selectedItem: _displaySettingsViewModel.languageCode,
                onItemSelected: _displaySettingsViewModel.onLanguageSelected,
                images: LanguageService.list.keys
                    .map((e) => Image.asset(
                        "assets/images/flags/${LanguageService.localeCountryCode[e]}.png"))
                    .toList(),
                matchingCriteria: (String code, String searchText) {
                  return LanguageService.list[code]?.toLowerCase().contains(searchText) ?? false;
                },
              ),

              if (FeatureFlag.customBackgroundEnabled)
                StandardListRow(
                  title: "Custom background",
                  isSelected: false,
                  onTap: (_) => _pickImage(context),
                ),

              if (responsiveLayoutUtil.shouldRenderMobileUI && DeviceInfo.instance.isMobile) ...[
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    S.current.appearance,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          height: 22 / 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SettingsChoicesCell(
                        ChoicesListItem<ThemeMode>(
                          title: "",
                          items: ThemeMode.values,
                          selectedItem: _displaySettingsViewModel.themeMode,
                          onItemSelected: (ThemeMode themeMode) =>
                              _displaySettingsViewModel.setThemeMode(themeMode),
                          displayItem: (ThemeMode themeMode) {
                            return themeMode.name[0].toUpperCase() +
                                themeMode.name.substring(1).toLowerCase();
                          },
                        ),
                        useGenericColor: false,
                        padding: EdgeInsets.all(12),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Semantics(
                              label: S.of(context).color_theme,
                              child: SettingsThemeChoicesCell(_displaySettingsViewModel),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }),
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
