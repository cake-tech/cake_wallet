import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_selector.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart';
import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
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
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/settings/display_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';

class DisplaySettingsPage extends StatelessWidget {
  DisplaySettingsPage(this._displaySettingsViewModel);


  final DisplaySettingsViewModel _displaySettingsViewModel;

  @override
  Widget build(BuildContext context) {
    return ModalPageWrapper(
      topBar: ModalTopBar(
        title: S.of(context).display,
        leadingIcon: Icon(Icons.arrow_back_ios_new),
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
        content: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (responsiveLayoutUtil.shouldRenderMobileUI &&
                  DeviceInfo.instance.isMobile) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 14),
                  child: Text(
                    S.current.appearance,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      height: 0.2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  decoration: ShapeDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(18))),
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
                        padding: EdgeInsets.all(14),
                      ),
                      Container(
                        decoration: ShapeDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.circular(18))),
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
              Observer(
                builder: (_) => NewListSections(
                  sections: {
                    "": [
                      ListItemToggle(
                          keyValue: "apps",
                          label: S.of(context).apps,
                          value: _displaySettingsViewModel.shouldShowMarketPlaceInDashboard,
                          onChanged: (val) {
                            _displaySettingsViewModel.setShouldShowMarketPlaceInDashbaord(val);
                          }),
                      ListItemToggle(
                          keyValue: "display_settings_show_address_book_popup",
                          label: S.of(context).show_address_book_popup,
                          value: _displaySettingsViewModel.showAddressBookPopup,
                          onChanged: (val) {
                            _displaySettingsViewModel.setShowAddressBookPopup(val);
                          }),
                      ListItemToggle(
                          keyValue: "display_settings_disable_buy_button",
                          label: S.of(context).disable_buy,
                          value: _displaySettingsViewModel.disableTradeOption,
                          onChanged: (val) {
                            _displaySettingsViewModel.setDisableTradeOption(val);
                          }),
                      if (_displaySettingsViewModel.showZcashCardSetting)
                        ListItemToggle(
                            keyValue: "display_settings_show_zcashcard",
                            label: S.of(context).show_zcash_card,
                            value: _displaySettingsViewModel.showZcashCard,
                            onChanged: (val) {
                              _displaySettingsViewModel.setShowZcashCard(val);
                            }),
                      ListItemSelector(
                          keyValue: "display_settings_sync_status_display",
                          label: S.current.sync_status_display_mode,
                          options: [_displaySettingsViewModel.syncStatusDisplayMode.title],
                          onTap: () async {
                            final items = SyncStatusDisplayMode.values.toList();

                            final selectedAtIndex =
                            items.indexOf(_displaySettingsViewModel.syncStatusDisplayMode);

                            await showPopUp<void>(
                              context: context,
                              builder: (_) => Picker(
                                items: items,
                                selectedAtIndex: selectedAtIndex,
                                mainAxisAlignment: MainAxisAlignment.start,
                                onItemSelected: (SyncStatusDisplayMode mode) {
                                  _displaySettingsViewModel.setSyncStatusDisplayMode(mode);
                                },
                                displayItem: (SyncStatusDisplayMode mode) => mode.title,
                                isSeparated: false,
                              ),
                            );
                          }),
                      if (_displaySettingsViewModel.showDisplayAmountsInSatoshiSetting)
                        ListItemRegularRow(
                            keyValue: "display_settings_bitcoin_amount_display",
                            label: S.of(context).bitcoin_amount_display,
                            trailingText: _displaySettingsViewModel.displayAmountsInSatoshi.title,
                            onTap: () async {
                              final items = BitcoinAmountDisplayMode.all;

                              final selectedAtIndex =
                              items.indexOf(_displaySettingsViewModel.displayAmountsInSatoshi);

                              await showPopUp<void>(
                                context: context,
                                builder: (_) => Picker(
                                  items: items,
                                  selectedAtIndex: selectedAtIndex,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  onItemSelected: _displaySettingsViewModel.setDisplayAmountsInSatoshi,
                                  displayItem: (BitcoinAmountDisplayMode mode) => mode.title,
                                  isSeparated: false,
                                ),
                              );
                            }),
                      if (!_displaySettingsViewModel.disabledFiatApiMode)
                        ListItemRegularRow(
                            keyValue: "display_settings_fiat_currency",
                            label: S.of(context).settings_currency,
                            trailingText: _displaySettingsViewModel.fiatCurrency.title,
                            onTap: () async {
                              final items = FiatCurrency.all;

                              final selectedAtIndex =
                              items.indexOf(_displaySettingsViewModel.fiatCurrency);

                              await showPopUp<void>(
                                context: context,
                                builder: (_) => Picker(
                                  items: items,
                                  selectedAtIndex: selectedAtIndex,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  onItemSelected: (FiatCurrency currency) {
                                    _displaySettingsViewModel.setFiatCurrency(currency);
                                  },
                                  images: FiatCurrency.all
                                      .map((e) => Image.asset("assets/images/flags/${e.countryCode}.png"))
                                      .toList(),
                                  hintText: S.of(context).search_currency,
                                  isGridView: true,
                                  matchingCriteria: (FiatCurrency currency, String searchText) {
                                    return currency.title.toLowerCase().contains(searchText) ||
                                        currency.fullName.toLowerCase().contains(searchText);
                                  },
                                  isSeparated: false,

                                ),
                              );
                            }),
                      ListItemRegularRow(
                          keyValue: "display_settings_language",
                          label: S.of(context).settings_change_language,
                          trailingText: LanguageService.list[_displaySettingsViewModel.languageCode] ?? '',
                          onTap: () async {
                            final items = LanguageService.list.keys.toList();

                            final selectedAtIndex =
                            items.indexOf(_displaySettingsViewModel.languageCode);

                            await showPopUp<void>(
                              context: context,
                              builder: (_) => Picker(
                                displayItem: (dynamic code) {
                                  return LanguageService.list[code] ?? '';
                                },
                                items: items,
                                selectedAtIndex: selectedAtIndex,
                                mainAxisAlignment: MainAxisAlignment.start,
                                onItemSelected: _displaySettingsViewModel.onLanguageSelected,
                                images: LanguageService.list.keys
                                    .map((e) => Image.asset(
                                    "assets/images/flags/${LanguageService.localeCountryCode[e]}.png"))
                                    .toList(),
                                hintText: S.of(context).search_language,
                                matchingCriteria: (String code, String searchText) {
                                  return LanguageService.list[code]?.toLowerCase().contains(searchText) ?? false;
                                },
                                isSeparated: true,

                              ),
                            );
                          }),
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
