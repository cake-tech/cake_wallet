import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/language_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_choices_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_picker_cell.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_switcher_cell.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/themes/theme_list.dart';
import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:cake_wallet/view_model/settings/settings_view_model.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class DisplaySettingsPage extends BasePage {
  DisplaySettingsPage(this.settingsViewModel);

  @override
  String get title => S.current.display_settings;

  final SettingsViewModel settingsViewModel;

  @override
  Widget body(BuildContext context) {
    return Observer(builder: (_) {
      return Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            SettingsSwitcherCell(
            title: S.current.settings_display_balance,
            value:  settingsViewModel.shouldDisplayBalance,
            onValueChange: (_, bool value) {
               settingsViewModel.setShouldDisplayBalance(value);          
            }),
            if (!isHaven)
              SettingsPickerCell<FiatCurrency>(
                title: S.current.settings_currency,
                searchHintText: S.current.search_currency,
                items: FiatCurrency.all,
                selectedItem: settingsViewModel.fiatCurrency,
                onItemSelected: (FiatCurrency currency) => settingsViewModel.setFiatCurrency(currency),
                images: FiatCurrency.all.map((e) => Image.asset("assets/images/flags/${e.countryCode}.png")).toList(),
                isGridView: true,
                matchingCriteria: (FiatCurrency currency, String searchText) {
                  return currency.title.toLowerCase().contains(searchText) ||
                      currency.fullName.toLowerCase().contains(searchText);
                },
              ),
            SettingsPickerCell<String>(
              title: S.current.settings_change_language,
              searchHintText: S.current.search_language,
              items: LanguageService.list.keys.toList(),
              displayItem: (dynamic code) {
                return LanguageService.list[code] ?? '';
              },
              selectedItem: settingsViewModel.languageCode,
              onItemSelected: settingsViewModel.onLanguageSelected,
              images: LanguageService.list.keys
                  .map((e) => Image.asset("assets/images/flags/${LanguageService.localeCountryCode[e]}.png"))
                  .toList(),
              matchingCriteria: (String code, String searchText) {
                return LanguageService.list[code]?.toLowerCase().contains(searchText) ?? false;
              },
            ),
            SettingsChoicesCell(
              ChoicesListItem<ThemeBase>(
                title: S.current.color_theme,
                items: ThemeList.all,
                selectedItem: settingsViewModel.theme,
                onItemSelected: (ThemeBase theme) => settingsViewModel.setTheme(theme),
              ),
            ),
          ],
        ),
      );
    });
  }
}
